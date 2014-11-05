require 'selenium-webdriver'
require 'watir-webdriver'
require "watir-webdriver/extensions/alerts"
module LapisLazuli
  class Browser
    @ll
    @browser

    def initialize(ll)
      @ll = ll
      browser = ENV['BROWSER']
      if browser.nil?
        browser =  @ll.config('browser', 'firefox')
      end
      case browser.downcase
        when 'firefox'
          @browser = Watir::Browser.new :firefox
        when 'chrome'
          # Check Platform running script
          if RUBY_PLATFORM.downcase.include?("linux")
            Watir::Browser::Chrome.path = "/usr/lib/chromium-browser/chromium-browser"
          end
          @browser = Watir::Browser.new :chrome
        when 'safari'
          @browser = Watir::Browser.new :safari
        when 'ie'
          require 'rbconfig'
          if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
            @browser = Watir::Browser.new :ie
          else
            raise "You can't run IE tests on non-Windows machine"
          end
        when 'ios'
          if RUBY_PLATFORM.downcase.include?("darwin")
            @browser = Watir::Browser.new :iphone
          else
            raise "You can't run IOS tests on non-mac machine"
          end
        else
          # Defaults to firefox
          @ll.log.info("Couldn't determine the browser to use. Using firefox")
          @browser = Watir::Browser.new :firefox
      end
    end

    def has_error?
      if not @ll.has_config("error_strings")
        return false
      end
      begin
        page_text = @browser.html
        @ll.config("error_strings").each do |error|
          if page_text.scan(error)[0]
            return true
          end
        end
      rescue RuntimeError => err
        @ll.log.debug "Cannot read the html for page #{@browser.url}: #{err}"
      end
      return false
    end
    # Taking a screenshot of the current page. Using the name as defined at the start of every scenario
    def take_screenshot
      begin
        fileloc = @ll.config("screenshot_dir","screenshots") + '/' + @ll.scenario.timecode + '.jpg'
        @browser.driver.save_screenshot(fileloc)
        @ll.log.debug "Screenshot saved: #{fileloc}"
      rescue Exception => e
        @ll.log.debug "Failed to save screenshot. Error message #{e.message}"
      end
    end

    def method_missing(meth, *args, &block)
      if @browser.respond_to? meth
        return @browser.send(meth.to_s, *args, &block)
      end
      raise "Method Missing: #{meth}"
    end
  end
end
