require 'open-uri'
require 'nokogiri'
class Innowhite

  attr_accessor :mod_name, :org_name, :sub, :server_address, :private_key

  def initialize(mod_name, org_name = nil)
    load_settings
    @mod_name = mod_name.gsub(/ /,'')
    @org_name = org_name.nil? ? @parent_org : org_name
  end

  def load_settings
    settings = YAML.load_file('config/innowhite.yml')
    @server_address = settings["innowhite"]["server_address"]
    @private_key = settings["innowhite"]["private_key"]
    @parent_org = settings["innowhite"]["organization"]
  end

  def create_room
    room_id = set_room_id
    address = join_room_helper(@server_address,@org_name, room_id, @mod_name,true)
    return {:address => address, :room_id => room_id}
  end

  def set_room_id
    room_id = ""
    doc = Nokogiri::XML(open("#{@server_address}CreateRoom?parentOrg=#{@parent_org}&orgName=#{@org_name}&user=#{@mod_name}&checksum=#{generate_checksum(@parent_org,@org_name, @mod_name)}"))
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
    address = join_room_helper(@server_address,@org_name, room_id, user, false)
    return address
  end

  def get_sessions(status)
    ids = []
    descs = []
    res = []
    url = URI.escape("http://innowhite.com/get_active_session?orgName=#{@org_name}&status=#{status}")

    x = Nokogiri::XML(open(url))
    x.xpath('//web-session/session-id').each{|m| ids << m.text}
    x.xpath('//web-session/session-desc').each{|m| descs << m.text}

    ids.each_with_index do |id, index|
      res << {:id => id, :description => descs[index]}
    end
    return res
  end

  private

  def join_room_helper(server_addr, org_name, room_id,user, is_teacher)
    action = "#{server_addr}JoinRoom?"
    address = "parentOrg=#{@parent_org}&orgName=#{org_name}&roomId=#{room_id}&user=#{user}&roomLeader=#{is_teacher}"
    checksum = address+@private_key
    return "#{action}#{address}&checksum=#{generating_checksum(checksum)}"
  end

  def generating_checksum(params)
    Digest::SHA1.hexdigest(params)
  end

  def generate_checksum(parent_org, org_name,user_name)
    Digest::SHA1.hexdigest(generate_information_url(parent_org, org_name,user_name))
  end

  def generate_information_url(parent_org, org_name,user_name)
    "parentOrg=#{parent_org}&orgName=#{org_name}&user=#{user_name}#{@private_key}"
  end

end