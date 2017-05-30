#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
module WorldModule
  ##
  # Module with error handling related functionality
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

      # Default actions
      screenshot = false
      exception = nil

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

          # Exception message shouldn't get lost
          if settings.has_key? :exception and not settings[:exception].nil?
            exception = settings[:exception]
            if message.nil?
              message = settings[:exception].message
            else
              message = "#{message} - #{settings[:exception].message}"
            end
          elsif message.nil?
            message = "An unknown error occurred."
          end

          # Check if we want to take a screenshot
          if settings.has_key? :screenshot
            screenshot = !!settings[:screenshot]
          end
        end
      end

      # Include URL if we have a browser
      if self.has_browser?
        message += "\n---[ #{self.browser.url} ]---"
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
      if screenshot
        self.browser.take_screenshot(message)
      end

      # Start debugger, if necessary
      if self.env_or_config("breakpoint_on_error")
        self.start_debugger
      end

      # Raise the message
      if not exception.nil?
        # message already contains ex.message here - or it should
        raise exception.class, message, exception.backtrace
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
  end # module Error
end # module WorldModule
end # module LapisLazuli
