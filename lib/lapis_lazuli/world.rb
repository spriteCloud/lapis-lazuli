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
require "lapis_lazuli/config"
require "lapis_lazuli/variable"
require "lapis_lazuli/error"
require "lapis_lazuli/xpath"

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

    include LapisLazuli::Config
    include LapisLazuli::Variable
    include LapisLazuli::Error
    include LapisLazuli::XPath

    # session key
    @uuid
    attr_reader :log, :scenario, :time, :api, :proxy
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


        # Register a finalizer, so we can clean up the browser again
        ObjectSpace.define_finalizer(self, self.class.proxy_destroy(@proxy, @log))

        @log.debug("Found proxy: #{proxy_ip}:#{proxy_port}, spritecloud: #{proxy_master}")
      rescue StandardError => err
        @log.debug("No proxy available: #{err}")
      end
    end

    ##
    # Checks if there is a proxy
    def has_proxy?
      return !@proxy.nil?
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

        # Register a finalizer, so we can clean up the browser again
        ObjectSpace.define_finalizer(self, self.class.browser_destroy(@browser, @log))
      end
      return @browser
    end

  private

    def self.browser_destroy(browser, log)
      proc {
        if not browser.nil?
          begin
            browser.close
          rescue
            log.debug("Failed to close the browser, probably chrome")
          end
        end
      }
    end

    def self.proxy_destroy(proxy, log)
      proc {
        if not proxy.nil?
          begin
            proxy.close
          rescue
            log.debug("Failed to close the proxy")
          end
        end
      }
    end

  end # class World
end # module LapisLazuli
