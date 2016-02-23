#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2016 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'selenium-webdriver'
require 'watir-webdriver'
require "watir-webdriver/extensions/alerts"

require "lapis_lazuli/ast"

# Modules
require "lapis_lazuli/browser/error"
require 'lapis_lazuli/browser/find'
require "lapis_lazuli/browser/wait"
require "lapis_lazuli/browser/screenshots"
require "lapis_lazuli/browser/interaction"
require "lapis_lazuli/browser/remote"
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
    include LapisLazuli::Ast

    include LapisLazuli::BrowserModule::Error
    include LapisLazuli::BrowserModule::Find
    include LapisLazuli::BrowserModule::Wait
    include LapisLazuli::BrowserModule::Screenshots
    include LapisLazuli::BrowserModule::Interaction
    include LapisLazuli::BrowserModule::Remote
    include LapisLazuli::GenericModule::XPath

    @@world=nil
    @@cached_browser_options={}
    @@browsers=[]
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
    @browser_name
    @browser_wanted
    @optional_data

    attr_reader :browser_name, :browser_wanted, :optional_data

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
      @optional_data = @optional_data.dup
      @browser = create_driver(@browser_wanted, @optional_data)
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
      end
    end

    ##
    # Close and create a new browser
    def restart
      world.log.debug "Restarting browser"
      @browser.close
      self.start
    end

    ##
    # Closes the browser and updates LL so that it will open a new one if needed
    def close(reason = nil, remove_from_list=true)
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
      when "end"
        # Also ignored here - this is handled  in World.browser_destroy
      else
        if is_last_scenario?(scenario)
          # Close it
          LapisLazuli::Browser.close_all close_browser_after
        end
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

    def self.close_all(reason=nil)
      # A running browser should exist and we are allowed to close it
      if @@browsers.length != 0 and @@world.env_or_config("close_browser_after") != "never"
        # Notify user
        @@world.log.debug("Closing all browsers")

        # Close each browser
        @@browsers.each do |b|
          begin
            b.close reason, false
          rescue Exception => err
            # Provide some details
            @@world.log.debug("Failed to close the browser, probably chrome: #{err.to_s}")
          end
        end

        # Make sure the array is cleared
        @@browsers = []
      end
    end

    private
      ##
      # The main browser window for testing
      def init(browser_wanted=(no_browser_wanted=true;nil), optional_data=(no_optional_data=true;nil))
        # Store the optional data so on restart of the browser it still has the
        # correct configuration
        if no_optional_data and optional_data.nil? and @@cached_browser_options.has_key?(:optional_data) and (browser_wanted.nil? or browser_wanted == @@cached_browser_options[:browser])
          optional_data = @@cached_browser_options[:optional_data]
        elsif optional_data.nil?
          optional_data = {}
        end

        # Do the same caching stuff for the browser
        if no_browser_wanted and browser_wanted.nil? and @@cached_browser_options.has_key?(:browser)
          browser_wanted = @@cached_browser_options[:browser]
        end


        if !@@cached_browser_options.has_key? :browser
          @@cached_browser_options[:browser] = browser_wanted
          # Duplicate the data as Webdriver modifies it
          @@cached_browser_options[:optional_data] = optional_data.dup
        end

        @browser_wanted = browser_wanted
        @optional_data = optional_data
        # Create the browser
        create_driver(@browser_wanted, @optional_data)
      end

      ##
      # Create a new browser depending on settings
      # Always cached the supplied arguments
      def create_driver(browser_wanted=nil, optional_data=nil)
        # No browser? Does the config have a browser? Default to firefox
        if browser_wanted.nil?
          browser_wanted = world.env_or_config('browser', 'firefox')
        end

        # Select the correct browser
        case browser_wanted.to_s.downcase
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
        @browser_name = b.to_s
        if b == :remote
          # Get the config
          remote_config = world.env_or_config("remote", {})

          # The settings we are going to use to create the browser
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

          args.push(remote_browser_config(remote_settings))
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
          browser_instance = Watir::Browser.new(*args)
        rescue Selenium::WebDriver::Error::UnknownError => err
          raise err
        end
        return browser_instance
      end
  end

end
