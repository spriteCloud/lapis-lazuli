require 'selenium-webdriver'
require 'watir-webdriver'
require "watir-webdriver/extensions/alerts"
module LapisLazuli
  ##
  # Extension to the Watir browser
  class Browser
    @ll
    @browser

    def initialize(ll)
      @ll = ll
      # Create a new browser
      @browser = self.create
    end

    ##
    # Create a new browser depending on settings
    def create(browser_wanted)
      browser = nil
      # Use the supplied browser or from the ENV
      browser_name = browser_wanted || ENV['BROWSER']
      # Do we have a browser in the config, default to firefox
      # TODO: Should we check the ll.env instead of ll.config?
      if browser_name.nil?
        browser_name =  @ll.config('browser', 'firefox')
      end

      # Select the correct browser
      case browser_name.downcase
        when 'firefox'
          browser = Watir::Browser.new :firefox
        when 'chrome'
          # Check Platform running script
          if RUBY_PLATFORM.downcase.include?("linux")
            Watir::Browser::Chrome.path = "/usr/lib/chromium-browser/chromium-browser"
          end
          browser = Watir::Browser.new :chrome
        when 'safari'
          browser = Watir::Browser.new :safari
        when 'ie'
          require 'rbconfig'
          if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
            browser = Watir::Browser.new :ie
          else
            raise "You can't run IE tests on non-Windows machine"
          end
        when 'ios'
          if RUBY_PLATFORM.downcase.include?("darwin")
            browser = Watir::Browser.new :iphone
          else
            raise "You can't run IOS tests on non-mac machine"
          end
        else
          # Defaults to firefox
          @ll.log.info("Couldn't determine the browser to use. Using firefox")
          browser = Watir::Browser.new :firefox
      end
      return browser
    end

    ##
    # Close and create a new browser
    def restart
      @browser.close
      @browser = self.create
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

      if block.nil?
        # We need a block to execute the waiting
        raise "Incorrect settings"
      elsif settings.has_key? :condition and settings[:condition] == :while
        # Do a while wait if asked nicely
        Watir::Wait.while(timeout, message, &block)
      else
        # By default do a wait until
        Watir::Wait.until(timeout, message, &block)
      end
    end

    ##
    # Find DOM elements
    #
    # Examples:
    # findAll(:text_field => :first)
    # findAll(:text_field => {:name => "test"})
    # findAll(:text_field => "test") (searches based on name or id)
    #
    # TODO: Add a lot more like select, options, list..
    def findAll(settings)
      error = true
      if settings.has_key? :error and not settings[:error]
        error = false
      end

      if settings.has_key? :text_field
        text_field = settings[:text_field]
        if text_field == :first
          p "First field"
          return @browser.text_fields(:type => "text") ||
            (error and @ll.error("First inputfield not found"))
        elsif text_field.is_a? Hash
          return @browser.text_fields(text_field) ||
            (error and @ll.error("First inputfield not found"))
        else
          text_field = text_field.to_s
          begin
            # Find it based on name or id
            xpath = @browser.text_fields(
                :xpath,
                "//*[@name='#{text_field}' or @id='#{text_field}']"
              )
            return xpath
          rescue
            @ll.error("Could not find a text field with name or id equal to '#{text_field}'")
          end
        end
      end
      @ll.error("Incorrect settings for find")
    end

    ##
    # Same as findAll only it filters present elements
    def findAllPresent(settings)
      self.findAll(settings).find_all do |element|
        begin
          element.present?
        rescue
          false
        end
      end
    end

    ##
    # By default it selects the first element of findAllPresent
    # add settings[:present] = false to use findAll
    # TODO: Add :last, :random instead of first of always having the first element
    def find(settings)
      # Output
      result = nil
      # Should we use findAll
      if settings.has_key? :present and not settings[:present]
        result = self.findAll(settings)
      else
        # Default is findAllPresent
        result = self.findAllPresent(settings)
      end

      # A Watir collection
      if result.is_a? Watir::ElementCollection
        return result.first
      # or an array
      elsif result.is_a? Array
        return result[0]
      else
        # We didn't get the result we wanted
        @ll.error("Incorrect settings for find #{result}")
      end
    end

    ##
    # Does this page have errors?
    # Checks the pagetext for error_strings that are specified in the config
    def has_error?
      # Need some error strings
      if not @ll.has_config?("error_strings")
        return false
      end

      begin
        # Get the HTML of the page
        page_text = @browser.html
        # Try to find all errors
        @ll.config("error_strings").each do |error|
          if page_text.scan(error)[0]
            # Stop if we found one
            return true
          end
        end
      rescue RuntimeError => err
        # An error?
        # TODO: Check if we need to return true here
        @ll.log.debug "Cannot read the html for page #{@browser.url}: #{err}"
      end
      # By default we don't have errors
      return false
    end

    ##
    # Taking a screenshot of the current page.
    # Using the name as defined at the start of every scenario
    def take_screenshot
      begin
        fileloc = @ll.config("screenshot_dir","screenshots") +
          '/' + @ll.scenario.time.timestampe + "_" @ll.scenario.name + '.jpg'
        # Save the screenshot
        @browser.driver.save_screenshot(fileloc)
        @ll.log.debug "Screenshot saved: #{fileloc}"
      rescue Exception => e
        @ll.log.debug "Failed to save screenshot. Error message #{e.message}"
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
      raise "Method Missing: #{meth}"
    end
  end
end
