#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2015 spriteCloud B.V. and other LapisLazuli contributors.
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
  # included here can rely on @world being set to the current cucumber world
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
    include LapisLazuli::GenericModule::Assertions

    @world
    @browser
    @cached_browser_wanted
    @cached_optional_data

    @browser_name
    attr_reader :browser_name

    def initialize(world, *args)
      # The class only works with some modules loaded; they're loaded by the
      # Browser module, but we can't be sure that's been used.
      assert world.respond_to?(:config), "Need to include LapisLazuli::WorldModule::Config in your cucumber world."
      assert world.respond_to?(:log), "Need to include LapisLazuli::WorldModule::Logging in your cucumber world."
      assert world.respond_to?(:error), "Need to include LapisLazuli::WorldModule::Error in your cucumber world."
      assert world.respond_to?(:has_proxy?), "Need to include LapisLazuli::WorldModule::Proxy in your cucumber world."

      @world = world

      # Create a new browser with optional arguments
      @browser = self.init(*args)

      # Add registered world modules.
      if not LapisLazuli::WorldModule::Browser.browser_modules.nil?
        LapisLazuli::WorldModule::Browser.browser_modules.each do |ext|
          self.extend(ext)
        end
      end
    end

    ##
    # The main browser window for testing
    def init(browser_wanted=(no_browser_wanted=true;nil), optional_data=(no_optional_data=true;nil))
      # Store the optional data so on restart of the browser it still has the
      # correct configuration
      if no_optional_data and optional_data.nil? and @cached_optional_data
        optional_data = @cached_optional_data
      elsif optional_data.nil?
        optional_data = {}
      else
        # Duplicate the data as Webdriver modifies it
        @cached_optional_data = optional_data.dup
      end

      # Do the same caching stuff for the browser
      if no_browser_wanted and browser_wanted.nil? and @cached_browser_wanted
        browser_wanted = @cached_browser_wanted
      else
        @cached_browser_wanted = browser_wanted
      end

      # Create the browser
      self.create_internal(browser_wanted, optional_data)
    end

    ##
    # Creates a new browser instance.
    def create(*args)
      return Browser.new(@world, *args)
    end

    ##
    # Create a new browser depending on settings
    # Always cached the supplied arguments
    def create_internal(browser_wanted=nil, optional_data=nil)
      # No browser? Does the config have a browser? Default to firefox
      if browser_wanted.nil?
        browser_wanted = @world.env_or_config('browser', 'firefox')
      end

      # Select the correct browser
      case browser_wanted.to_s.downcase
        when 'chrome'
          # Check Platform running script
          browser = :chrome
        when 'safari'
          browser = :safari
        when 'ie'
          require 'rbconfig'
          if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
            browser = :ie
          else
            @world.error("You can't run IE tests on non-Windows machine")
          end
        when 'ios'
          if RUBY_PLATFORM.downcase.include?("darwin")
            browser = :iphone
          else
            @world.error("You can't run IOS tests on non-mac machine")
          end
        when 'remote'
          browser = :remote
        else
          browser = :firefox
      end

      args = [browser]
      @browser_name = browser.to_s
      if browser == :remote
        remote_settings = @world.env_or_config("remote", {})
        @world.log.debug("Using remote browser: #{remote_settings}")
        args.push(remote_browser_config(remote_settings))
      elsif not optional_data.nil? and not optional_data.empty?
        @world.log.debug("Got optional data: #{optional_data}")
        args.push(optional_data)
      elsif @world.has_proxy?
        # Create a session if needed
        if !@world.proxy.has_session?
          @world.proxy.create()
        end

        proxy_url = "#{@world.proxy.ip}:#{@world.proxy.port}"
        if browser == :firefox
          @world.log.debug("Configuring Firefox proxy: #{proxy_url}")
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

    ##
    # Return if the browser is open
    def is_open?
      return !@browser.nil?
    end

    ##
    # Start the browser if it's not yet open.
    def start
      if @browser.nil?
        @browser = self.init
      end
    end

    ##
    # Close and create a new browser
    def restart
      @world.log.debug "Restarting browser"
      @browser.close
      self.start
    end

    ##
    # Closes the browser and updates LL so that it will open a new one if needed
    def close(reason = nil)
      if not @browser.nil?
        if not reason.nil?
          reason = " after #{reason}"
        else
          reason = ""
        end

        @world.log.debug "Closing browser#{reason}: #{@browser}"
        @browser.close
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
      close_browser_after = @world.env_or_config("close_browser_after")

      case close_browser_after
      when "scenario"
        # We always close it
        self.close close_browser_after
      when "never"
        # Do nothing: party time, excellent!
      when "end"
        # Also ignored here - this is handled  in World.browser_destroy
      else
        if is_last_scenario?(scenario)
          # Close it
          self.close close_browser_after
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
      if "end" == world.env_or_config("close_browser_after")
        begin
          self.close "end"
        rescue
          world.log.debug("Failed to close the browser, probably chrome")
        end
      end
    end
  end
end
