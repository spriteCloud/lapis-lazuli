#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
require "json"
require "singleton"
require "securerandom"
require "lapis_lazuli/logger"
require "lapis_lazuli/scenario"
require "lapis_lazuli/browser"
require "lapis_lazuli/options"
require "lapis_lazuli/config"
require "lapis_lazuli/variable"
require "lapis_lazuli/error"

module LapisLazuli
  ##
  # World class that handles everything
  #
  # Singleton class so that you can get the configuration everywhere
  # Used in LapisLazuli module to extend the cucumber World.
  #
  # Example
  #   ll = LapisLazuli::World.instance
  #   ll.config("default_env")
  #   ll.browser.goto("http://www.spritecloud.com")
  #   ll.log.debug("LL example")
  #   ll.scenario.id
  class World
    include Singleton

    include LapisLazuli::Config
    include LapisLazuli::Variable
    include LapisLazuli::Error

    # session key
    @uuid
    attr_reader :log, :scenario, :time
    attr_accessor :scenario, :time, :browser

    ##
    # Initialize of the singleton. Only called once
    # Sets the env to TEST_ENV and populates time with starttime
    def initialize
      if ENV["TEST_ENV"]
        @env = ENV["TEST_ENV"]
      end
      time = Time.now

      @time = {
        :timestamp => time.strftime('%y%m%d_%H%M%S'),
        :epoch => time.to_i.to_s
      }

      @uuid = SecureRandom.hex

      # Current scenario information
      @scenario = Scenario.new

      # Load the configuration file
      self.load_config(LapisLazuli.config_file)

      # We should have a config
      if @config.nil?
        raise "Could not load a configuration"
      end

      # Make log directory
      dir = self.env_or_config('log_dir')
      begin
        Dir.mkdir dir
      rescue SystemCallError => ex
        # Swallow this error; it occurs (amongst other situations) when the
        # directory exists. Checking for an existing directory beforehand is
        # not concurrency safe.
      end

      # Start the logger with the config filename
      log_file = "#{dir}#{File::SEPARATOR}#{File.basename(LapisLazuli.config_file, ".*")}.log"
      # Or a filename from the environment
      if self.has_env_or_config?("log_file")
        log_file = self.env_or_config("log_file")
      end
      @log = TeeLogger.new(log_file)
      @log.level = self.env_or_config("log_level")
    end


    ##
    # Checks if there is a browser started
    def has_browser?
      return !@browser.nil?
    end

    ##
    # Get the current main browser
    def browser(*args)
      if @browser.nil?
        # Add LL to the arguments for the browser
        browser_args = args.unshift(self)
        # Create a new browser object
        @browser = Browser.send(:new, *browser_args)
      end
      return @browser
    end

  end # class World
end # module LapisLazuli