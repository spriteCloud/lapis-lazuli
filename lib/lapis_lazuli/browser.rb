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

module LapisLazuli
  ##
  # Extension to the Watir browser
  class Browser
    @ll
    @browser
    @cached_browser_wanted
    @cached_optional_data

    def initialize(ll, *args)
      @ll = ll
      # Create a new browser with optional arguments
      @browser = self.send(:init, *args)
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

      browser_instance = Watir::Browser.send(:new, *args)
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
    # Wait with options, uses Watir::Wait. Timeout defaults to 10
    #
    # Examples
    # wait(:timeout => 5, :text => "Hello World")
    # wait(:timeout => 5, :text => /Hello World/i)
    # wait(:timeout => 10, :html => "<span>", :condition => :while)
    def wait(settings)
      # Default Message
      message = "Waiting"
      # Timeout
      timeout = 10
      # Set the timeout if settings has one
      if settings.has_key? :timeout
        timeout = settings[:timeout].to_i
      end

      # Placeholder for the block we want
      block = nil
      if settings.has_key? :text
        # Waiting for text
        text = settings[:text]
        message = "Waiting for text '#{text}'"
        # Do we use regular expressions
        if text.is_a? Regexp
          block = lambda {|arg|
            self.browser.text =~ text
          }
        else
          # Plain-text matching
          block = lambda {|arg|
            self.browser.text.include?(text)
          }
        end
      # Waiting for HTML
      elsif settings.has_key? :html
        html = settings[:html]
        message = "Waiting for html '#{html}'"
        block = lambda {|arg|
          self.browser.html.include?(html)
        }
      end

      begin
        if block.nil?
          # We need a block to execute the waiting
          @ll.error("Incorrect settings")
        elsif settings.has_key? :condition and settings[:condition] == :while
          # Do a while wait if asked nicely
          Watir::Wait.while(timeout, message, &block)
        else
          # By default do a wait until
          Watir::Wait.until(timeout, message, &block)
        end
      rescue Watir::Wait::TimeoutError => err
        settings[:message] = err.message
        @ll.error(settings)
      end
    end

    ##
    # Find DOM elements
    #
    # Examples:
    # findAll(:like => [:a, :href, "account/login"])
    # findAll(:text_field => {:name => "test"})
    # findAll(:text_field => "test") (xpath search based on name, id or text)
    # findAll(:text_field => {})
    def findAll(settings)
      context = @browser
      has_context = false

      settings = parseFindSettings settings

      # A context is starting position for the search
      # Example:
      #  parent = ll.browser.find(:div => "some_parent")
      #  ll.browser.find(:a => "some_link", :context => parent)
      if settings.include? :context
        context = settings[:context]
        has_context = true
      end

      if settings.include? :like
        like_opts = settings[:like]
        # Convert array shorthand to full Hash
        if like_opts.is_a? Array and like_opts.length == 3
          like_opts = {
            :element => like_opts[0],
            :attribute => like_opts[1],
            :include => like_opts[2]
          }
        elsif like_opts.is_a? Symbol
          like_opts = {
            :element => like_opts,
          }
        end

        # Did we receive the correct input
        if like_opts.is_a? Hash and
          like_opts.include? :element
            # Basic xpath to find an element
            xpath = "#{'.' if has_context}//#{like_opts[:element]}"

            # Add options to the xpath
            if like_opts.include? :attribute and like_opts.include? :include
              # Create new variable so we don't overwrite the old one
              attribute = nil
              # Do we need to match text or an attirbute
              if like_opts[:attribute].to_sym == :text
                attribute = "text()"
              else
                attribute = "@#{like_opts[:attribute]}"
              end

              # Add the options to the xpath query
              xpath = "#{xpath}[contains(concat(' ',#{attribute},' '), '#{like_opts[:include]}')]"
            end

            # Create the XPath query
            return context.elements(
              :xpath,
              xpath
            )
        end
        @ll.error("Incorrect settings for find like")
      end

      # For all settings
      settings.each do |key, value|
        # Find the one the browser responds to
        # Example : text_fields or buttons
        function_name = "#{key.to_s}s"
        if context.respond_to? function_name
          # If the value is a hash use it as arguments for this function
          if value.is_a? Hash
            return context.send(function_name, value)
          else
            string = value.to_s
            begin
              # Find it based on name,id or text
              xpath = context.send(
                  function_name,
                  :xpath,
                  "#{'.' if has_context}//*[@name='#{string}' or @id='#{string}' or text()='#{string}']"
                )
              return xpath
            rescue
              settings[:message] = "Could not find any #{function_name} with name, id or text equal to '#{string}'"
              @ll.error(settings)
            end
          end
        end
      end
      # We need one function to respond..
      @ll.error("Incorrect settings for find #{settings}")
    end

    ##
    # Same as findAll only it filters present elements
    def findAllPresent(settings)
      self.findAll(settings).find_all {|element|
        begin
          element.present?
        rescue
          false
        end
      }
    end

    ##
    # Randomized find
    # Returns an Enumerator
    #
    # Example:
    # enum = ll.browser.findRandomized(:button => {:class => "button"})
    # a_button = enum.next()
    # a_different_button = enum.next()
    #
    # Enumerator raises StopIteration error on next() if list is exhausted
    def findRandomized(settings)
      function = :findAll
      if not settings.nil? and settings.has_key? :present and not settings[:present]
        function = :findAllPresent
      end
      return self.send(function, settings).to_a.shuffle.each
    end

    ##
    # By default it selects the first element of findAllPresent
    # add settings[:present] = false to use findAll
    def find(settings)
      error = true
      settings = parseFindSettings settings

      # Find the first one that is present on the page
      if settings.is_a? Array
        result = nil
        i = 0
        while i < settings.length do
          setting = settings[i]
          config = setting.dup
          # Do not throw errors, except on the last search
          if i != settings.length - 1
            config[:error] = false
          end
          result = self.find(config)
          break unless result.nil?
          i += 1
        end

        #return the result
        return result
      end

      if settings.has_key? :error and not settings[:error]
        error = false
      end

      # Output
      result = nil
      # Should we use findAll
      if settings.has_key? :present and not settings[:present]
        result = self.findAll(settings)
      else
        # Default is findAllPresent
        result = self.findAllPresent(settings)
      end

      element = nil
      # A Watir collection
      if result.is_a? Watir::ElementCollection or result.is_a? Array
        # By default pick the first
        element = result.first
        # Do we need to pic a different one?
        if settings.has_key? :pick
          if settings[:pick] == :last
            # The last
            element = result.last
          elsif settings[:pick] == :random
            element = result.to_a.shuffle.first
          elsif settings[:pick].is_a? Numeric
            # Or based on a number
            element = result[settings[:pick]]
          end
        end
      else
        # We didn't get the result we wanted
        @ll.error("Incorrect settings for find #{settings} #{result}")
      end

      # Throw an error if not found
      if error and element.nil?
        # Send all settings to the error function, allows for groups information ext.
        settings[:message] = "Could not find element with settings: #{settings}"
        @ll.error(settings)
      else
        return element
      end
    end

    ##
    # Does this page have errors?
    # Checks the pagetext for error_strings that are specified in the config
    def has_error?
      errors = self.get_html_errors
      js_errors = self.get_js_errors
      if not js_errors.nil?
        errors += js_errors
      end

      if errors.length > 0 or self.get_http_status.to_i > 299
        errors.each do |error|
          if error.is_a? Hash
            @ll.log.debug("#{error["message"]} #{error["url"]} #{error["line"]} #{error["column"]}\n#{error["stack"]}")
          else
            @ll.log.debug("#{error}")
          end
        end
        return true
      end
      return false
    end

    def get_html_errors
      result = []
      # Need some error strings
      if @ll.has_env_or_config?("error_strings")
        begin
          # Get the HTML of the page
          page_text = @browser.html
          # Try to find all errors
          @ll.env_or_config("error_strings").each {|error|
            if page_text.include? error
              # Add to the result list
              result.push error
            end
          }
        rescue RuntimeError => err
          # An error?
          @ll.log.debug "Cannot read the html for page #{@browser.url}: #{err}"
        end
      end
      # By default we don't have errors
      return result
    end

    def get_js_errors
      return self.browser.execute_script <<-JS
        try {
          return lapis_lazuli.errors;
        } catch(err){
          return null;
        }
      JS
    end

    def get_http_status
      return self.browser.execute_script <<-JS
        try{
          return lapis_lazuli.http.statusCode;
        } catch(err){
          return null;
        }
      JS
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

      # Generate the file name according to the new or old scheme.
      name = nil
      case @ll.env_or_config("screenshot_scheme")
      when "new"
        name = "#{@ll.scenario.time[:iso_short]}-#{@ll.scenario.id}-#{Random.rand(10000).to_s}.png"
      else # 'old' and default
        name = @ll.scenario.data.name.gsub(/^.*(\\|\/)/, '').gsub(/[^\w\.\-]/, '_').squeeze('_')
        name = @ll.time[:timestamp] + "_" + name + '.png'
      end

      # Full file location
      fileloc = "#{dir}#{File::SEPARATOR}#{name}"

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

    private

    ##
    # Convert all shortcut settings to a full settings hash
    def parseFindSettings(settings)
      if settings.is_a? String
        settings = {:element => settings}
      elsif settings.is_a? Symbol
        settings = {:like => settings}
      elsif settings.is_a? Array
        settings = settings.map do |setting|
          parseFindSettings setting
        end
      end

      return settings
    end
  end
end
