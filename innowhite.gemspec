# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{innowhite}
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{bainur}]
  s.date = %q{2011-08-11}
  s.description = %q{Innowhite Api}
  s.email = %q{inoe.bainur@gmail.com}
  s.extra_rdoc_files = [%q{README.rdoc}, %q{lib/innowhite.rb}]
  s.files = [%q{README.rdoc}, %q{Rakefile}, %q{lib/innowhite.rb}, %q{Manifest}, %q{innowhite.gemspec}]
  s.homepage = %q{http://github.com/bainur/innowhite}
  s.rdoc_options = [%q{--line-numbers}, %q{--inline-source}, %q{--title}, %q{Innowhite}, %q{--main}, %q{README.rdoc}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{innowhite}
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Gem for Innowhite Api}
  s.add_dependency 'nokogiri', '1.5.0'
  s.add_dependency 'rest-client', '1.6.3'

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
