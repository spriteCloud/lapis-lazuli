#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'selenium-webdriver'
require 'watir-webdriver'
require "watir-webdriver/extensions/alerts"
require 'test/unit/assertions'

# Modules
require "lapis_lazuli/browser/error"
require 'lapis_lazuli/browser/find'
require "lapis_lazuli/browser/wait"
require 'lapis_lazuli/generic/xpath'

module LapisLazuli
  ##
  # Extension to the Watir browser
  class Browser
    include Test::Unit::Assertions

    include LapisLazuli::BrowserModule::Error
    include LapisLazuli::BrowserModule::Find
    include LapisLazuli::BrowserModule::Wait
    include LapisLazuli::GenericModule::XPath

    @ll
    @browser
    @cached_browser_wanted
    @cached_optional_data

    def initialize(ll, *args)
      @ll = ll
      # Create a new browser with optional arguments
      @browser = self.init(*args)
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
      self.create(browser_wanted, optional_data)
    end

    ##
    # Create a new browser depending on settings
    # Always cached the supplied arguments
    def create(browser_wanted=nil, optional_data=nil)
      browser = nil

      # No browser? Does the config have a browser? Default to firefox
      if browser_wanted.nil?
        browser_wanted = @ll.env_or_config('browser', 'firefox')
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
            @ll.error("You can't run IE tests on non-Windows machine")
          end
        when 'ios'
          if RUBY_PLATFORM.downcase.include?("darwin")
            browser = :iphone
          else
            @ll.error("You can't run IOS tests on non-mac machine")
          end
        else
          browser = :firefox
      end

      args = [browser]
      if not optional_data.nil?
        args.push(optional_data)
      end

      browser_instance = Watir::Browser.new(*args)
      return browser_instance
    end

    ##
    # Close and create a new browser
    def restart
      @ll.log.debug "Restarting browser"
      @browser.close
      @browser = self.init
    end

    ##
    # Closes the browser and updates LL so that it will open a new one if needed
    def close
      @ll.log.debug "Closing browser"
      @browser.close
      # Update LL that we don't have a browser anymore...
      @ll.browser = nil
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
    # Valid config options: feature, scenario, never
    # Default: feature
    def close_after_scenario(scenario)
      # Determine the config
      close_browser_after = @ll.env_or_config("close_browser_after", "feature")

      @ll.log.debug "Close after #{close_browser_after}"

      case close_browser_after
      when "scenario"
        # We always close it
        self.close
      when "never"
        # Do nothing: party time, excellent!
      else
        case scenario
        when Cucumber::Ast::Scenario
          # Is this scenario the last one of its feature?
          if scenario.feature.feature_elements.last == scenario
            # Close it
            self.close
          end
        when Cucumber::Ast::OutlineTable::ExampleRow
          # Is this the last scenario in this feature?
          if scenario.scenario_outline.feature.feature_elements.last == scenario.scenario_outline
            # And is this the last example in the table?
            is_last_example = false
            scenario.scenario_outline.each_example_row do |row|
              is_last_example = row == scenario
            end
            # Then close it
            if is_last_example
              self.close
            end
          end
        end
      end
    end


    ##
    # Returns the name of the screenshot, if take_screenshot is called now.
    def screenshot_name(suffix="")
      dir = @ll.env_or_config("screenshot_dir")

      # Generate the file name according to the new or old scheme.
      name = nil
      case @ll.env_or_config("screenshot_scheme")
      when "new"
        # FIXME random makes this non-repeatable, sadly
        name = "#{@ll.scenario.time[:iso_short]}-#{@ll.scenario.id}-#{Random.rand(10000).to_s}.png"
      else # 'old' and default
        name = @ll.scenario.data.name.gsub(/^.*(\\|\/)/, '').gsub(/[^\w\.\-]/, '_').squeeze('_')
        name = @ll.time[:timestamp] + "_" + name + '.png'
      end

      # Full file location
      fileloc = "#{dir}#{File::SEPARATOR}#{name}"

      return fileloc
    end

    ##
    # Taking a screenshot of the current page.
    # Using the name as defined at the start of every scenario
    def take_screenshot(suffix="")
      # If the target directory does not exist, create it.
      dir = @ll.env_or_config("screenshot_dir")
      begin
        Dir.mkdir dir
      rescue SystemCallError => ex
        # Swallow this error; it occurs (amongst other situations) when the
        # directory exists. Checking for an existing directory beforehand is
        # not concurrency safe.
      end

      fileloc = self.screenshot_name(suffix)

      # Write screenshot
      begin
        # Save the screenshot
        @browser.screenshot.save fileloc
        @ll.log.debug "Screenshot saved: #{fileloc}"
      rescue RuntimeError => e
        @ll.log.debug "Failed to save screenshot to '#{fileloc}'. Error message #{e.message}"
      end
    end

    ##
    # Map any missing method to the browser object
    # Example
    # ll.browser.goto "http://www.spritecloud.com"
    def method_missing(meth, *args, &block)
      if @browser.respond_to? meth
        return @browser.send(meth.to_s, *args, &block)
      end
      @ll.error("Browser Method Missing: #{meth}")
    end


  end
end
