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
require 'lapis_lazuli/xpath'
require 'lapis_lazuli/find'

module LapisLazuli
  ##
  # Extension to the Watir browser
  class Browser
    include Test::Unit::Assertions
    include LapisLazuli::XPath
    include LapisLazuli::Find

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
    # Waits for multiple elements, each specified by any number of watir
    # selectors. Instead of using tag name function directly, specify the
    # :tag_name field, e.g.:
    #
    # elements = wait_multiple(
    #   {:tag_name => 'a', :class => /foo/},
    #   {:tag_name => 'div', :id => "bar"}
    # )
    #
    # By default, the function waits for an element to become present. You
    # can, however, specify which condition the function should wait for for
    # each individual element:
    #
    # elements = wait_multiple(
    #   {:tag_name => 'a', :class => /foo/, :wait_for => :exists?},
    #   {:tag_name => 'div', :id => "bar", :wait_for => :present?}
    # )
    #
    # In addition to standard watir selectors, this function accepts the
    # following:
    #   :text       - searches for the given text. The value may be a regular
    #                 expression (slow).
    #   :html       - searches for the given HTML.
    #
    # Finally, wait_multiple accepts options; if options are specified, then
    # the element list to wait for must be provided as the :list option, e.g.:
    #
    # elements.wait_multiple(
    #   :timeout => 3,
    #   :list => [
    #     {:tag_name => 'a', :class => /foo/, :wait_for => :exists?},
    #     {:tag_name => 'div', :id => "bar", :wait_for => :present?}
    #  ]
    # )
    #
    # The options wait_multiple accepts are:
    #   :timeout    - a timeout to wait for, in seconds. Defaults to 10
    #   :operator   - either :one_of or :all_of; specifies whether one or all
    #                 of the elements must fulfil their :wait_for condition
    #                 for the condition to be successful. Defaults to :one_of.
    #   :condition  - either :until or :while; specifies whether the function
    #                 waits until the conditions are met, or while the
    #                 conditions are met. Defaults to :until
    #
    def wait_multiple(*args)
      # Default options
      options = {
        :timeout => 10,
        :condition => :until,
        :operator => :one_of,
        :list => args,
        :screenshot => false,
        :groups => nil,
      }

      # If we have a single hash argument, we'll treat this as options, and
      # expect the :list field.
      if 1 == args.length and args[0].is_a? Hash
        opts = args[0]
        options.each do |k, v|
          if not opts.has_key? k
            opts[k] = v
          end
        end

        assert opts.has_key?(:list), "Need to provide a list of element selectors."

        options = opts
      end

      # Ensure correct types
      options[:timeout] = options[:timeout].to_i
      options[:condition] = options[:condition].to_sym
      options[:operator] = options[:operator].to_sym

      # pp "Options", options

      # Construct the code to be evaluated
      all = []
      options[:list].each do |item|
        # Extract and store additional information
        method = item.fetch(:wait_for, "present?").to_sym
        item.delete(:wait_for)

        # :text and :html are synonymous
        text = item.fetch(:text, item.fetch(:html, nil))
        item.delete(:text)
        item.delete(:html)

        # Function for finding/filtering the element
        matcher = lambda {
          # Basics: find it.
          if item.empty?
            # @ll.log.debug("No element specified; starting with the entire document.")
            elem = @browser
          else
            elem = self.element(item)
            # @ll.log.debug("Finding element(#{item}) => #{elem}")
          end

          # Check whether the method returns true
          if not item.empty?
            res = elem.send(method)
            # @ll.log.debug("Checking elem.#{method} => #{res}")
            if not res
              return false
            end
          end

          # Now do the text matching
          if not text.nil?
            if text.is_a? Regexp and elem.text =~ text
              # @ll.log.debug("Matched against regex #{text}")
              return elem
            elsif elem.text.include? text
              # @ll.log.debug("Matched to include string #{text}")
              return elem
            else
              # @ll.log.debug("No text match")
              return false
            end

          else
            # No matching to perform
            return elem
          end
        }

        all << matcher
      end

      # p "Eval: #{all}"

      # Generate the block for evaluating "all" items.
      all_block = nil
      case options[:operator]
      when :all_of
        all_block = lambda {
          all.each do |func|
            res = func.call
            # @ll.log.debug("Got: #{res}")
            if not res
              return false
            end
          end
          return true
        }
      when :one_of
        all_block = lambda {
          all.each do |func|
            res = func.call
            # @ll.log.debug("Got: #{res}")
            if res
              return true
            end
          end
          return false
        }
      else
        options[:message] = "Invalid operatior '#{options[:operator]}'."
        @ll.error(options)
      end

      # Wait for it all to happen. What we're calling depends on the
      # condition.
      err = nil
      begin
        case options[:condition]
        when :until
          res = Watir::Wait.until(options[:timeout]) { all_block.call }
        when :while
          res = Watir::Wait.while(options[:timeout]) { all_block.call }
        else
          options[:message] = "Invalid condition '#{options[:condition]}'."
          @ll.error(options)
        end
      rescue Watir::Wait::TimeoutError => e
        @ll.log.debug("Caught timeout: #{e}")
        err = e
      end

      # p "Error: #{err}"

      # If we didn't get a timeout error, we know that some of the specified
      # arguments meet their condition; let's find out which ones.
      results = []
      all.each do |func|
        res = func.call
        if res
          results << res
        end
      end

      # p "Results: #{results}"

      # Handle errors
      if not err.nil? and results.empty?
        options[:exception] = err
        @ll.error(options)
      end

      results
    end

    ##
    # Wait with options, uses Watir::Wait. Timeout defaults to 10
    #
    # Examples
    # wait(:timeout => 5, :text => "Hello World")
    # wait(:timeout => 5, :text => /Hello World/i)
    # wait(:timeout => 10, :html => "<span>", :condition => :while)
    def wait(settings)
      # Get options
      options = {}

      options[:timeout] = settings.fetch(:timeout, 10)
      settings.delete(:timeout)

      options[:condition] = settings.fetch(:condition, :until)
      settings.delete(:condition)

      options[:groups] = settings.fetch(:groups, nil)
      settings.delete(:groups)

      options[:screenshot] = settings.fetch(:screenshot, false)
      settings.delete(:screenshot)

      # List of one element
      options[:list] = [settings]

      elems = self.wait_multiple(options)

      if elems.length > 0
        return elems.first
      end
      return nil
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
