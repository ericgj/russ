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

