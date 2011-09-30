require 'open-uri'
require 'nokogiri'
require 'rest-client'
require 'pp'
class Innowhite

  attr_accessor :mod_name, :org_name, :sub, :server_address, :private_key

  def initialize
    load_settings
    #@mod_name = mod_name.gsub(/ /,'')
    #@org_name = org_name.nil? ? @parent_org : org_name
  end

  def load_settings
    settings = YAML.load_file('config/innowhite.yml')
    @server_address = settings["innowhite"]["server_address"]
    @api_address = settings["innowhite"]["api_address"]
    @private_key = settings["innowhite"]["private_key"]
    @parent_org = settings["innowhite"]["organization"]
    @org_name = @parent_org
  end

  def create_room(params = {})
    params[:parentOrg] ||= @parent_org
    params[:orgName] ||= @org_name
    user = params[:user]
    tags = params[:tags]
    desc = params[:desc]
    #parent_org = params[:parentOrg]
    @org_name = @parent_org if @org_name.nil?
    room_id = set_room_id
    address = join_room_helper(@server_address,@org_name, room_id, user,true)
    res = create_room_info(room_id,user,tags,desc, @org_name,address)
    res = res.include?("Missing")
    if res == true
      return "Failed to fetch, maybe you have entered wrong username / organization name .."
    else
      return {:address => address, :room_id => room_id}
    end
  end

  def create_room_info(room_id,user,tags,desc, parent_org,address)
    checksum_tmp = "parentOrg=#{parent_org}&orgName=#{parent_org}"
    checksum = generating_checksum(URI.escape(checksum_tmp))
    
    res = RestClient.post("#{@api_address}create_room_info",
      {:roomId => room_id, :user => user, :tags => tags,:desc => desc,
        :parentOrg => parent_org, :address => address, :orgName => parent_org,
        :checksum => checksum
        }
    )
    return res
  end

  def set_room_id
    room_id = ""
    url = "#{@server_address}CreateRoom?parentOrg=#{@parent_org}&orgName=#{@org_name}&user=#{@mod_name}&checksum=#{generate_checksum(@parent_org,@org_name, @mod_name)}"    
    doc = Nokogiri::XML(open(url))
    status = doc.xpath('//returnStatus').text.gsub("\n","") rescue ""
    if status.include?('SUCCESS')
      room_id = doc.xpath('//roomId').text.gsub("\n","").to_i
    elsif status.include?('AUTH_FAILED')
      room_id = "AUTH_FAILED"
    elsif status.include?('EXPIRED')
      room_id = 'EXPIRED'
    elsif status.include?('OUT_OF_SERVICE')
      room_id = 'OUT_OF_SERVICE'
    else
      room_id = "Error With the Server #{@server_address}CreateRoom?parentOrg=#{@parent_org}&orgName=#{@org_name}&user=#{@mod_name}&checksum=#{generate_checksum(@parent_org,@org_name, @mod_name)}"
    end
    return room_id
  end

  def join_meeting(room_id, user)
    url = "#{@api_address}exist_session?roomId=#{room_id}"
    doc = Nokogiri::XML(open(url))
    missing = false
    if doc.text.blank?
      missing = true
    end    
    address = join_room_helper(@server_address,@org_name, room_id, user, false)
    if missing
      raise "Room is not exist / Expired"
    else
      return address
    end
    
  end
  
  def past_sessions(params = {})
    begin
      params[:parentOrg] ||= @parent_org
      org_name1 = params[:parentOrg] if params[:orgName].nil?
      ids = []
      parent_org = params[:parentOrg]
      user = params[:user]
      tags = params[:tags]
      descs = []
      res = []
      tmp = "parentOrg=#{parent_org}&orgName=#{org_name1}&user=#{user}&tags=#{tags}"
      checksum_tmp = "parentOrg=#{parent_org}&orgName=#{org_name1}"
      checksum = generating_checksum(URI.escape(checksum_tmp))
     # pp  "#{@api_address}list_sessions?#{tmp}&cheksum=#{checksum}"
      url = URI.escape("#{@api_address}past_sessions?#{tmp}&checksum=#{checksum}")

      x = Nokogiri::XML(open(url))
      x.xpath('//web-session/session-id').each{|m| ids << m.text}
      x.xpath('//web-session/session-desc').each{|m| descs << m.text}

      ids.each_with_index do |id, index|
        res << {:id => id, :description => descs[index]}
      end
      return res
    rescue => e
      return "Error fetching sessions check the organization and private key .."
    end
  end
  
  def get_sessions(params = {})
    begin
    params[:parentOrg] ||= @parent_org
    if params[:orgName].nil?
      org_name1 = params[:parentOrg]
    else
      org_name1 = params[:orgName]
    end
    ids = []
    parent_org = params[:parentOrg]
    org_name1 = parent_org if org_name1.blank?
    user = params[:user]
    tags = params[:tags]
    descs = []
    res = []
    checksum_tmp = "parentOrg=#{parent_org}&orgName=#{org_name1}"    
    tmp = "parentOrg=#{parent_org}&orgName=#{org_name1}&user=#{user}&tags=#{tags}"
    checksum = generating_checksum(URI.escape(checksum_tmp))    
    url = URI.escape("#{@api_address}list_sessions?#{tmp}&checksum=#{checksum}")

    x = Nokogiri::XML(open(url))
    x.xpath('//web-session/session-id').each{|m| ids << m.text}
    x.xpath('//web-session/session-desc').each{|m| descs << m.text}

    ids.each_with_index do |id, index|
      res << {:id => id, :description => descs[index]}
    end
    return res
    rescue => e
      return "Error fetching sessions check the organization and private key .."
    end
  end

  # A call to schedule a session
  #
  #

  def schedule_meeting(params = {})
    @org_name ||= params[:orgName]
    tags = params[:tags]
    start_time = params[:startTime]
    time_zone = params[:timeZone]
    end_time = params[:endTime]
    user = params[:user]
    desc = params[:description]
    room_id = set_room_id

    address = join_room_helper(@server_address,@org_name, room_id, user,true)    
    create_schedule(room_id, user, tags,desc, @parent_org, address,start_time,end_time, time_zone)
  end

  def create_schedule(room_id,user,tags,desc, parent_org,address, start_time, end_time, time_zone)
    checksum_tmp = "parentOrg=#{parent_org}&orgName=#{parent_org}"
    checksum = generating_checksum(URI.escape(checksum_tmp))
    address = join_room_helper(@server_address,@org_name, room_id, user,true)    
    res = RestClient.post("#{@api_address}create_schedule_meeting",
      {:roomId => room_id, :user => user, :tags => tags,:desc => desc,:startTime => start_time,
        :endTime => end_time, :timeZone => time_zone,
        :parentOrg => parent_org, :address => address, :orgName => parent_org,
        :checksum => checksum
        }
    )
    return res
  end

  def get_scheduled_list(params={})
    @org_name ||= params[:orgName]
    checksum = main_cheksum(@parent_org, @org_name)
    tags = params[:tags] if params[:tags]
    
    par = url_generator(@parent_org, @org_name)
    url = URI.escape("#{@api_address}get_scheduled_sessions?#{par}&checksum=#{checksum}&tags=#{tags}")
    x = Nokogiri::XML(open(url))
    ids = [], start_at = [], end_at = [], zone = []
    desc = []
    x.xpath('//web-session/session-id').each{|m| ids << m.text}
    x.xpath('//web-session/session-desc').each{|m| desc << m.text}    
    x.xpath('//web-session/start-at').each{|m| start_at << m.text.to_time.to_i rescue 0}
    x.xpath('//web-session/end-at').each{|m| end_at << m.text.to_time.to_i rescue 0}
    x.xpath('//web-session/start-at').each{|m| zone << m.text.to_datetime.utc_offset rescue 0}
    
    res = []
    ids.each_with_index do |id, index|
      res << {
        :tags => tags, :orgName => @org_name,
        :room_id => id,
        :startTime => start_at[index], :timeZone => zone[index],
        :endTime => end_at[index],
        :moderatorName => "",
        :room_desc => desc[index]
      }
    end
    return res
  end


  def cancel_meeting(room_id)
    checksum = main_cheksum(@parent_org, @org_name)
    par = url_generator(@parent_org, @org_name)
    url = URI.escape("#{@api_address}cancel_meeting?roomId=#{room_id}&#{par}&checksum=#{checksum}")

    x = Nokogiri::XML(open(url))
    return x.xpath("//success").map(&:text)
  end

  def update_schedule(params = {})
    checksum = main_cheksum(@parent_org, @org_name)    
    room_id = params[:room_id]
    start_time = params[:startTime] if params[:startTime]
    time_zone = params[:timeZone] if params[:timeZone]
    end_time = params[:endTime] if params[:endTime]
    desc = params[:description] if params[:description]
    tags = params[:tags]

    res = RestClient.put("#{@api_address}update_schedule",
      {:roomId => room_id, :tags => tags,:description => desc,
        :parentOrg => @parent_org, :orgName => @org_name,
        :checksum => checksum
        }
    )
  end



  private

  def url_generator(parent_org,org_name)
    url = "parentOrg=#{parent_org}&orgName=#{org_name}"
    return url
  end
  def main_cheksum(parent_org, org_name)
    checksum_tmp = url_generator(parent_org, org_name)
    checksum = generating_checksum(URI.escape(checksum_tmp))
    return checksum
  end

  def join_room_helper(server_addr, org_name, room_id,user, is_teacher)
    action = "#{server_addr}JoinRoom?"
    address = "parentOrg=#{@parent_org}&orgName=#{org_name}&roomId=#{room_id}&user=#{user}&roomLeader=#{is_teacher}"
    checksum = address+@private_key
    return "#{action}#{address}&checksum=#{generating_checksum(checksum)}"
  end

  def generating_checksum(params)    
    Digest::SHA1.hexdigest(params+@private_key)
  end

  def generate_checksum(parent_org, org_name,user_name)
    Digest::SHA1.hexdigest(generate_information_url(parent_org, org_name,user_name))
  end

  def generate_information_url(parent_org, org_name,user_name)
    "parentOrg=#{parent_org}&orgName=#{org_name}&user=#{user_name}#{@private_key}"
  end

end
