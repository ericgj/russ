gem 'minitest' 
require 'minitest/autorun'
require 'nokogiri'

module Fixtures

  def fixture_path
    File.expand_path('fixtures',File.dirname(__FILE__))
  end

  def fixture_file(name)
    File.join(fixture_path,name)
  end

  def fixture(name)
    File.read(fixture_file(name))
  end

  def xml_fixture(name)
    Nokogiri::XML(fixture(name))
  end

  def each_fixture(subdir='',&b)
    Dir[File.join(fixture_path,subdir,'*')].each do |f| yield File.read(f) end
  end
  
  def each_xml_fixture(subdir='',&b)
    each_fixture do |data| yield Nokogiri::XML(data) end
  end

end

