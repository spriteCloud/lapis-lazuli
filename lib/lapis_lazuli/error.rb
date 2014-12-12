#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
  ##
  # Module with error handling related functionality (World)
  module Error
    ##
    # Throw an error based on some settings
    #
    # Examples:
    # ll.error("Simple message") => "Simple message"
    # ll.error(:message => "Simple message") => "Simple message"
    # ll.error(:env => "test") => "Environment setting 'test' not found"
    # ll.error(:env => "test", :exists => true) => "Environment setting 'test' found"
    # ll.error(:screenshot => true, :message => "Simple") => "Simple", and screenshot is taken with the message name included.
    def error(settings=nil)
      # Default message
      message = nil
      groups = nil
      # Do we have settings
      if not settings.nil?
        # Simple string input
        if settings.is_a? String
          message = settings
        elsif settings.is_a? Hash
          if settings.has_key? :message
            message = settings[:message]
          end
          # Environment errors
          if settings.has_key? :env
            # Does the value exist or not?
            exists = ""
            if not (settings.has_key?(:exists) or settings[:exists])
              exists = ' not'
            end
            message = "Environment setting '#{settings[:env]}'" +
                      exists + " found"
          end

          if settings.has_key? :scenario
            message = "Scenario failed: #{settings[:scenario]}"
          elsif settings.has_key? :not_found
            message = "Not found: #{settings[:not_found]}"
          end

          # Grouping of errors
          if settings.has_key? :groups
            grouping = settings[:groups]
            if grouping.is_a? String
              groups = [grouping]
            elsif grouping.is_a? Array
              groups = grouping
            end
          end
        end
      end

      # Exception message shouldn't get lost
      if settings.has_key? :exception and not settings[:exception].nil?
        if message.nil?
          message = settings[:exception].message
        else
          message = "#{message} - #{settings[:exception].message}"
        end
      elsif message.nil?
        message = "An unknown error occurred."
      end

      # Include URL if we have a browser
      if self.has_browser?
        message += " (#{self.browser.url})"
      end

      # Add the groups to the message
      if not groups.nil?
        message = "[#{groups.join("][")}] #{message}"
      end

      # Write the error to the log
      if self.log
        self.log.error(message)
      end

      # Take screenshot, if necessary
      if settings.has_key? :screenshot and settings[:screenshot]
        self.browser.take_screenshot(message)
      end

      # Start debugger, if necessary
      if self.env_or_config("breakpoint_on_error")
        self.start_debugger
      end

      # Raise the message
      if settings.has_key? :exception and not settings[:exception].nil?
        ex = settings[:exception]
        # message already contains ex.message here - or it should
        raise ex.class, message, ex.backtrace
      else
        raise message
      end
    end

    ##
    # If byebug (ruby >= 2.0) or debugger (ruby < 2.0) are installed, start
    # the debugger now.
    def start_debugger
      # First try the more modern 'byebug'
      begin
        require "byebug"
        byebug
      rescue LoadError
        # If that fails, try the older debugger
        begin
          require 'debugger'
          debugger
        rescue LoadError
          self.log.info "No debugger found, can't break on failures."
        end
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


    ##
    # Retrieve errors from HTML elements, using the error_strings config
    # variable
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


    ##
    # If the proxy is supported, use it to retrieve JS errors.
    def get_js_errors
      return self.browser.execute_script <<-JS
        try {
          return lapis_lazuli.errors;
        } catch(err){
          return null;
        }
      JS
    end


    ##
    # If the proxy is supported, use it get the HTTP status code.
    def get_http_status
      return self.browser.execute_script <<-JS
        try{
          return lapis_lazuli.http.statusCode;
        } catch(err){
          return null;
        }
      JS
    end

  end # module Error
end # module LapisLazuli


