#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2016 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/ast"

# Modules
require "lapis_lazuli/driver/error"
require 'lapis_lazuli/driver/find'
require "lapis_lazuli/driver/wait"
require "lapis_lazuli/driver/screenshots"
require "lapis_lazuli/driver/interaction"
require "lapis_lazuli/driver/remote"
require 'lapis_lazuli/generic/xpath'
require 'lapis_lazuli/generic/assertions'

module LapisLazuli
  ##
  # Extension to a driver, such as the Watir browser or appium driver, etc.
  #
  # This class handles initialization, for the most part. DriverModules
  # included here can rely on world being set to the current cucumber world
  # object, and for some WorldModules to exist in it (see assertions in
  # constructor).
  class Driver
    include LapisLazuli::Ast

    include LapisLazuli::DriverModule::Error
    include LapisLazuli::DriverModule::Find
    include LapisLazuli::DriverModule::Wait
    include LapisLazuli::DriverModule::Screenshots
    include LapisLazuli::DriverModule::Interaction
    include LapisLazuli::DriverModule::Remote
    include LapisLazuli::GenericModule::XPath

    @@world=nil
    @@cached_driver_options={}
    @@drivers=[]
    class << self
      include LapisLazuli::GenericModule::Assertions

      def drivers
        return @@drivers
      end

      def add_driver(b)
        # Add destructor for all drivers
        Runtime.instance.set_if(self, :drivers, LapisLazuli::Driver.method(:close_all))
        @@drivers.push(b)
      end

      def remove_driver(b)
        @@drivers.delete(b)
      end

      def set_world(w)
        @@world = w
      end

      def check_world?
        assert @@world.respond_to?(:config), "Need to include LapisLazuli::WorldModule::Config in your cucumber world."
        assert @@world.respond_to?(:log), "Need to include LapisLazuli::WorldModule::Logging in your cucumber world."
        assert @@world.respond_to?(:error), "Need to include LapisLazuli::WorldModule::Error in your cucumber world."
        assert @@world.respond_to?(:has_proxy?), "Need to include LapisLazuli::WorldModule::Proxy in your cucumber world."
      end
    end

    @driver
    @driver_name
    @driver_wanted
    @optional_data

    attr_reader :driver_name, :driver_wanted, :optional_data

    def initialize(*args)
      # The class only works with some modules loaded; they're loaded by the
      # Driver module, but we can't be sure that's been used.
      LapisLazuli::Driver.check_world?

      self.start(*args)

      # Add registered world modules.
      if not LapisLazuli::WorldModule::Driver.driver_modules.nil?
        LapisLazuli::WorldModule::Driver.driver_modules.each do |ext|
          self.extend(ext)
        end
      end
    end

    # Support driver.dup to create a duplicate
    def initialize_copy(source)
      super
      @optional_data = @optional_data.dup
      @driver = create_driver(@driver_wanted, @optional_data)
      # Add this driver to the list of all drivers
      LapisLazuli::Driver.add_driver(self)
    end

    ##
    # Creates a new driver instance.
    def create(*args)
      return Driver.new(*args)
    end

    def world
      @@world
    end

    ##
    # Return if the driver is open
    def is_open?
      return !@driver.nil?
    end

    ##
    # Start the driver if it's not yet open.
    def start(*args)
      if @driver.nil?
        @driver = init(*args)
        # Add this driver to the list of all drivers
        LapisLazuli::Driver.add_driver(self)
      end
    end

    ##
    # Close and create a new driver
    def restart
      world.log.debug "Restarting driver"
      @driver.close
      self.start
    end

    ##
    # Closes the driver and updates LL so that it will open a new one if needed
    def close(reason = nil, remove_from_list=true)
      if not @driver.nil?
        if not reason.nil?
          reason = " after #{reason}"
        else
          reason = ""
        end

        world.log.debug "Closing driver #{reason}: #{@driver}"
        @driver.close
        if remove_from_list
          LapisLazuli::Driver.remove_driver(self)
        end
        @driver = nil
      end
    end

    ##
    # Same as close
    def quit
      self.close
    end

    ##
    # Close after scenario will close the driver depending on the close_browser_after
    # configuration
    #
    # Valid config options: feature, scenario, end, never
    # Default: feature
    def close_after_scenario(scenario)
      # Determine the config
      close_browser_after = world.env_or_config("close_browser_after")

      case close_browser_after
      when "scenario"
        # We always close it
        LapisLazuli::Driver.close_all close_browser_after
      when "never"
        # Do nothing: party time, excellent!
      when "end"
        # Also ignored here - this is handled  in World.driver_destroy
      else
        if is_last_scenario?(scenario)
          # Close it
          LapisLazuli::Driver.close_all close_browser_after
        end
      end
    end

    ##
    # Map any missing method to the driver object
    # Example
    # ll.driver.goto "http://www.spritecloud.com"
    def respond_to?(meth)
      if !@driver.nil? and @driver.respond_to? meth
        return true
      end
      return super
    end

    def method_missing(meth, *args, &block)
      if !@driver.nil? and @driver.respond_to? meth
        return @driver.send(meth.to_s, *args, &block)
      end
      return super
    end

    def destroy(world)
      # Primary driver should also close other drivers
      LapisLazuli::Driver.close_all("end")
    end

    def self.close_all(reason=nil)
      # A running driver should exist and we are allowed to close it
      if @@drivers.length != 0 and @@world.env_or_config("close_browser_after") != "never"
        # Notify user
        @@world.log.debug("Closing all drivers")

        # Close each driver
        @@drivers.each do |b|
          begin
            b.close reason, false
          rescue Exception => err
            # Provide some details
            @@world.log.debug("Failed to close the driver, probably chrome browser: #{err.to_s}")
          end
        end

        # Make sure the array is cleared
        @@drivers = []
      end
    end

    private
      ##
      # The main driver window for testing
      def init(driver_wanted=(no_driver_wanted=true;nil), optional_data=(no_optional_data=true;nil))
        # Store the optional data so on restart of the driver it still has the
        # correct configuration
        if no_optional_data and optional_data.nil? and @@cached_driver_options.has_key?(:optional_data) and (driver_wanted.nil? or driver_wanted == @@cached_driver_options[:driver])
          optional_data = @@cached_driver_options[:optional_data]
        elsif optional_data.nil?
          optional_data = {}
        end

        # Do the same caching stuff for the driver
        if no_driver_wanted and driver_wanted.nil? and @@cached_driver_options.has_key?(:driver)
          driver_wanted = @@cached_driver_options[:driver]
        end


        if !@@cached_driver_options.has_key? :driver
          @@cached_driver_options[:driver] = driver_wanted
          # Duplicate the data as Webdriver modifies it
          @@cached_driver_options[:optional_data] = optional_data.dup
        end

        @driver_wanted = driver_wanted
        @optional_data = optional_data
        # Create the driver
        create_driver(@driver_wanted, @optional_data)
      end

      ##
      # Create a new driver depending on settings
      # Always cached the supplied arguments
      def create_driver(driver_wanted=nil, optional_data=nil)
        # Run-time dependency.
        begin
          require 'selenium-webdriver'
          require 'watir-webdriver'
          require "watir-webdriver/extensions/alerts"
        rescue LoadError => err
          raise LoadError, "#{err}: you need to add 'watir-webdriver', 'watir-webdriver-performance' and 'watir-scroll' to your Gemfile before using the driver."
        end

        # No driver? Does the config have a driver? Default to firefox
        if driver_wanted.nil?
          driver_wanted = world.env_or_config('driver', 'firefox')
        end

        # Select the correct driver
        case driver_wanted.to_s.downcase
          when 'chrome'
            # Check Platform running script
            b = :chrome
          when 'safari'
            b = :safari
          when 'ie'
            require 'rbconfig'
            if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
              b = :ie
            else
              world.error("You can't run IE tests on non-Windows machine")
            end
          when 'ios'
            if RUBY_PLATFORM.downcase.include?("darwin")
              b = :iphone
            else
              world.error("You can't run IOS tests on non-mac machine")
            end
          when 'remote'
            b = :remote
          else
            b = :firefox
        end

        args = [b]
        @driver_name = b.to_s
        if b == :remote
          # Get the config
          remote_config = world.env_or_config("remote", {})

          # The settings we are going to use to create the driver
          remote_settings = {}

          # Add the config to the settings using downcase string keys
          remote_config.each{|k,v| remote_settings[k.to_s.downcase] = v}

          if optional_data.is_a? Hash
            # Convert the optional data to downcase string keys
            string_hash = Hash.new
            optional_data.each{|k,v| string_hash[k.to_s.downcase] = v}

            # Merge them with the settings
            remote_settings.merge! string_hash
          end

          args.push(remote_driver_config(remote_settings))
        elsif not optional_data.nil? and not optional_data.empty?
          world.log.debug("Got optional data: #{optional_data}")
          args.push(optional_data)
        elsif world.has_proxy?
          # Create a session if needed
          if !world.proxy.has_session?
            world.proxy.create()
          end

          proxy_url = "#{world.proxy.ip}:#{world.proxy.port}"
          if b == :firefox
            world.log.debug("Configuring Firefox proxy: #{proxy_url}")
            profile = Selenium::WebDriver::Firefox::Profile.new
            profile.proxy = Selenium::WebDriver::Proxy.new :http => proxy_url, :ssl => proxy_url
            args.push({:profile => profile})
          end
        end

        begin
          driver_instance = Watir::Browser.new(*args)
        rescue Selenium::WebDriver::Error::UnknownError => err
          raise err
        end
        return driver_instance
      end
  end

end
