# Load this before running tests against Ohm models and/or the Cuba app.
# Note that test_helper is loaded here, so only one require is needed.
#
# Note also that the redis server is assumed to be running locally on the
# default port. If it's not, execute `redis-server &` first, or fire it up 
# however you normally do.
#

require 'rack/test'
require_relative 'test_helper'
require_relative '../config/test/redis'
require_relative '../app'

module Russ
  class ModelSpec < MiniTest::Spec
    include Fixtures

    def setup
      super()
      Ohm.flush
    end

    def load_feed(fix)
      handler = Russ::AtomParser.new(Feed.new)
      Nokogiri::XML::SAX::Parser.new(handler).parse(fixture(fix))
    end
    
    def create_reader(attrs={})
      Reader.create attrs
    end

    def sub_reader(nick, uri, tags)
      Reader.with(:identity,nick).subscribe(Feed.with(:identity,uri),tags)
    end

  end

  class ControllerSpec < ModelSpec
    include Rack::Test::Methods

    def app
      Cuba
    end
  end

  ModelSpec.register_spec_type /model$/i, ModelSpec
  ControllerSpec.register_spec_type /controller$/i, ControllerSpec
  
end

