
module Tasks
module Redis
  class Shell
    
    def self.specify_options(p)
      p.opt 'env', 'environment', :default => 'development'
    end

    attr_accessor :options
    def env
      self.options['env']
    end

    def initialize(options)
      self.options = options
    end

    def call
      require 'ripl'
      require_relative "config/#{env}/redis"
      require_relative 'models'
     
      Ripl.start :argv => []
    end

  end
end
end

module R
  S = Tasks::Redis::Shell
end

