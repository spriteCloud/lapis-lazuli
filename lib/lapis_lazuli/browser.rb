#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2019 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
require "lapis_lazuli/ast"
# Modules
require "lapis_lazuli/browser/error"
require 'lapis_lazuli/browser/find'
require "lapis_lazuli/browser/wait"
require "lapis_lazuli/browser/screenshots"
require "lapis_lazuli/browser/interaction"
require 'lapis_lazuli/generic/xpath'
require 'lapis_lazuli/generic/assertions'

module LapisLazuli
  ##
  # Extension to the Watir browser
  #
  # This class handles initialization, for the most part. BrowserModules
  # included here can rely on world being set to the current cucumber world
  # object, and for some WorldModules to exist in it (see assertions in
  # constructor).
  class Browser

    include LapisLazuli::BrowserModule::Error
    include LapisLazuli::BrowserModule::Find
    include LapisLazuli::BrowserModule::Wait
    include LapisLazuli::BrowserModule::Screenshots
    include LapisLazuli::BrowserModule::Interaction
    include LapisLazuli::GenericModule::XPath

    @@world = nil
    @@cached_browser_options = {}
    @@browsers = []

    class << self
      include LapisLazuli::GenericModule::Assertions

      def browsers
        return @@browsers
      end

      def add_browser(b)
        # Add destructor for all browsers
        Runtime.instance.set_if(self, :browsers, LapisLazuli::Browser.method(:close_all))
        @@browsers.push(b)
      end

      def remove_browser(b)
        @@browsers.delete(b)
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

    @browser
    @browser_args

    attr_reader :browser_args

    def initialize(*args)
      # The class only works with some modules loaded; they're loaded by the
      # Browser module, but we can't be sure that's been used.
      LapisLazuli::Browser.check_world?

      self.start(*args)

      # Add registered world modules.
      if not LapisLazuli::WorldModule::Browser.browser_modules.nil?
        LapisLazuli::WorldModule::Browser.browser_modules.each do |ext|
          self.extend(ext)
        end
      end
    end

    # Support browser.dup to create a duplicate
    def initialize_copy(source)
      super
      @browser = create_driver(*@browser_args)
      # Add this browser to the list of all browsers
      LapisLazuli::Browser.add_browser(self)
    end

    ##
    # Creates a new browser instance.
    def create(*args)
      return Browser.new(*args)
    end

    def world
      @@world
    end

    ##
    # Return if the browser is open
    def is_open?
      return !@browser.nil?
    end

    ##
    # Start the browser if it's not yet open.
    def start(*args)
      if @browser.nil?
        @browser = init(*args)
        # Add this browser to the list of all browsers
        LapisLazuli::Browser.add_browser(self)
        # Making sure all browsers are gracefully closed when the exit event is triggered.
        at_exit { LapisLazuli::Browser::close_all 'exit event trigger' }
      end
    end

    ##
    # Close and create a new browser
    def restart(*args)
      world.log.debug "Restarting browser"
      self.close
      self.start(*args)
    end

    ##
    # Closes the browser and updates LL so that it will open a new one if needed
    def close(reason = nil, remove_from_list = true)
      if not @browser.nil?
        if not reason.nil?
          reason = " after #{reason}"
        else
          reason = ""
        end

        world.log.debug "Closing browser#{reason}: #{@browser}"
        @browser.close
        if remove_from_list
          LapisLazuli::Browser.remove_browser(self)
        end
        @browser = nil
      end
    end

    ##
    # Same as close
    def quit
      self.close
    end

    ##
    # Close after scenario will close the browser depending on the close_browser_after
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
        LapisLazuli::Browser.close_all close_browser_after
      when "never"
        # Do nothing: party time, excellent!
      when "feature"
        warn 'Close after feature is not supported anymore.'
      else
        # close after 'end' is now default
        # Also ignored here - this is handled  in World.browser_destroy
      end
    end

    ##
    # Map any missing method to the browser object
    # Example
    # ll.browser.goto "http://www.spritecloud.com"
    def respond_to?(meth)
      if !@browser.nil? and @browser.respond_to? meth
        return true
      end
      return super
    end

    def method_missing(meth, *args, &block)
      if !@browser.nil? and @browser.respond_to? meth
        return @browser.send(meth.to_s, *args, &block)
      end
      return super
    end

    def destroy(world)
      # Primary browser should also close other browsers
      LapisLazuli::Browser.close_all("end")
    end

    def self.close_all(reason = nil)
      # A running browser should exist and we are allowed to close it
      if @@browsers.length != 0 and @@world.env_or_config("close_browser_after") != "never"
        # Notify user
        @@world.log.debug("Closing all browsers")
        # Close each browser
        @@browsers.each do |b|
          b.close reason, true
        end

        # Make sure the array is cleared
        @@browsers = []
      end
    end

    private

    ##
    # The main browser window for testing
    def init(*args)
      # Store the optional data so on restart of the browser it still has the correct configuration
      create_driver(*args)
    end

    ##
    # Create a new browser depending on settings
    # Always cached the supplied arguments
    def create_driver(*args)
      # Remove device information from optional_data and create a separate variable for it
      device = args[1] ? args[1].delete(:device) : nil
      # If device is set, load it from the devices.yml config
      unless device.nil?
        begin
          world.add_config_from_file('./config/devices.yml')
        rescue
          raise '`./config/devices.yml` was not found. See http://testautomation.info/Lapis_Lazuli:Device_Simulation for more information'
        end
        if world.has_config? "devices.#{device}"
          device_configuration = world.config "devices.#{device}"
        else
          raise "Requested device `#{device}` was not found in the configuration. See http://testautomation.info/Lapis_Lazuli:Device_Simulation for more information"
        end
      end

      # Run-time dependency.
      begin
        require 'selenium-webdriver'
        require 'watir'
      rescue LoadError => err
        raise LoadError, "#{err}: you need to add 'watir' to your Gemfile before using the browser."
      end

      begin
        browser_instance = Watir::Browser.new(*args)
        # Resize the browser if the device simulation requires it
        if !device_configuration.nil? and !device_configuration['width'].nil? and !device_configuration['height'].nil?
          browser_instance.window.resize_to(device_configuration['width'], device_configuration['height'])
        end
      rescue Selenium::WebDriver::Error::UnknownError => err
        raise err
      end
      browser_instance
    end
  end

end
