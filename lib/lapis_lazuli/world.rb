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

# Classes
require "lapis_lazuli/logger"
require "lapis_lazuli/scenario"
require "lapis_lazuli/browser"
require "lapis_lazuli/api"
require "lapis_lazuli/proxy"

# Modules
require "lapis_lazuli/world/config"
require "lapis_lazuli/world/variable"
require "lapis_lazuli/world/error"
require "lapis_lazuli/generic/xpath"

# Other
require "lapis_lazuli/options"


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

    include LapisLazuli::WorldModule::Config
    include LapisLazuli::WorldModule::Variable
    include LapisLazuli::WorldModule::Error
    include LapisLazuli::GenericModule::XPath

    # session key
    @uuid
    attr_reader :log, :scenario, :time, :api, :proxy, :storage
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

      @api = API.new

      @uuid = SecureRandom.hex

      # Current scenario information
      @scenario = Scenario.new

      # Storage for the entire test run
      @storage = Storage.new
      @storage.set("time", @time)
      @storage.set("uuid", @uuid)

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

      # Check if we can start a proxy
      begin
        # Default proxy settings
        proxy_ip = "localhost"
        proxy_port = 10000
        proxy_master = true

        # Do we have a config?
        if self.has_env_or_config?("proxy.ip") and
          self.has_env_or_config?("proxy.port")
          proxy_ip = self.env_or_config("proxy.ip")
          proxy_port = self.env_or_config("proxy.port")
          proxy_master = self.env_or_config("proxy.spritecloud", true)
        end

        # Try to start the proxy
        @proxy = Proxy.new(proxy_ip, proxy_port, proxy_master)

        @log.debug("Found proxy: #{proxy_ip}:#{proxy_port}, spritecloud: #{proxy_master}")
      rescue StandardError => err
        @log.debug("No proxy available: #{err}")
      end

      # Register a finalizer, so we can clean up the proxy again
      ObjectSpace.define_finalizer(self, self.class.destroy(self))
    end

    ##
    # Checks if there is a proxy
    def has_proxy?
      return !@proxy.nil?
    end

    ##
    # Checks if there is a browser started
    def has_browser?
      return (not @browser.nil? and @browser.is_open?)
    end

    ##
    # Get the current main browser
    def browser(*args)
      if @browser.nil?
        # Add LL to the arguments for the browser
        browser_args = args.unshift(self)
        # Create a new browser object
        @browser = Browser.new(*browser_args)
      end

      if not @browser.is_open?
        @browser.start
      end

      return @browser
    end

  private

    def self.destroy(world)
      Proc.new do
        # First close the browser
        if world.has_browser?
          world.browser.destroy(world)
        end
        # Then the proxy
        if world.has_proxy?
          world.proxy.destroy(world)
        end

        # Finaly the storage
        # This will write a file with all data for this test
        world.storage.destroy(world)
      end
    end

  end # class World
end # module LapisLazuli
