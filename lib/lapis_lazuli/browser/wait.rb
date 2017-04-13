#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'lapis_lazuli/assertions'
require 'lapis_lazuli/argparse'

module LapisLazuli
module BrowserModule

  ##
  # Wait functionality for Browser
  module Wait
    include LapisLazuli::ArgParse

    ##
    # Same arguments as for the find functions, but a few more options are valid:
    #
    # :timeout    - specifies the timeout to wait for, defaulting to 10 seconds
    # :condition  - specifies the condition to wait for, either of :while or
    #               :until. The default is :until.
    # :screenshot - boolean flag determining whether a screenshot should be made
    #               if the function produces an error. The default is false.
    def multi_wait_all(*args)
      return internal_wait(:multi_find_all, *args)
    end

    def wait_all(*args)
      return internal_wait(:find_all, *args)
    end

    def multi_wait(*args)
      return internal_wait(:multi_find, *args)
    end

    def wait(*args)
      return internal_wait(:find, *args)
    end

  private

    ##
    # Internal wait function; public functions differ only in which of the find
    # functions they use.
    def internal_wait(find_func, *args)
      options = parse_wait_options(*args)

      # Extract our own options
      timeout = options[:timeout]
      options.delete(:timeout)

      retries = options[:stale_retries] + 1 # Add first attempt!
      options.delete(:stale_retries)

      condition = options[:condition]
      options.delete(:condition)

      # Removing context from the options to preven an error in Marshal.dump
      context = options[:selectors][0][:context]
      options[:selectors][0].delete(:context)

      # The easiest way to deal with find's new :throw policy is to set it to false.
      # We'll store the original value in a variable to catch it later.
      throw = options[:throw]
      options[:throw] = false

      # The proc we're waiting for invokes the find_func
      results = []
      has_single = false
      find_proc = lambda { |dummy|
        res = false
        err = nil
        err_msg = []
        retries.times do
          begin
            opts = Marshal.load(Marshal.dump(options))
            # Putting :context back in the selector if it was used
            opts[:selectors][0][:context] = context unless context.nil?
            results = send(find_func.to_sym, opts)

            if results.respond_to? :length
              res = (results.length > 0)
            else
              has_single = true
              results = [results]
              res = !!results[0]
            end
            break # don't need to retry
          rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
            # Sometimes the element becomes stale right when we're trying to check its presence.
            err = e
            err_msg << e.message
          rescue Watir::Exception::UnknownObjectException => e
            # Sometimes watir returns an unknown object exception, this should be caught when it's a wait until loop.
            err = e
            err_msg << e.message
          end
          # Retry
        end

        # Raise the error if the retries didn't suffice
        if not err.nil? and not res === false
          raise err, "Tried #{retries} times, but got: \n#{err_msg.join("\n")}\n", err.backtrace
        end

        # Return the results!
        res
      }

      # Call the appropriate condition function.
      err = nil
      begin
        res = Watir::Wait.send(condition, timeout: timeout, &find_proc)
      rescue Watir::Wait::TimeoutError => e
        world.log.debug("Caught timeout: #{e}")
        begin
          # Catch the default error and add the selectors to it.
          unless throw === false
            # Only raise an error if :throw is not false
            raise Watir::Wait::TimeoutError, "#{e.message} with selectors: #{options[:selectors]}"
          end
        rescue Watir::Wait::TimeoutError => err
          options[:exception] = err
          options[:message] = optional_message('Error in wait', options)
          world.error(options)
        end
      end

      # Filter out any nil results
      filter_results = results.select {|i| not i.nil?}
      # Error handling
      if not err.nil? and filter_results.empty?
        options[:exception] = err
        world.error(options)
      end

      # Set if the underlying find function returns single results
      if has_single
        # In chrome, somehow results can be no array, but still has_single is true
        return results[0] if results.kind_of?(Array)
        return results
      end
      return results
    end



    ##
    # Parses wait options, using parse_args
    def parse_wait_options(*args)
      options = {
        :timeout => 10,
        :stale_retries => 3,
        :condition => :until,
        :screenshot => false,
        :throw => true
      }
      options = ERROR_OPTIONS.merge options
      options = parse_args(options, :selectors, *args)

      # Validate options
      options[:timeout] = options[:timeout].to_i
      options[:screenshot] = !!options[:screenshot]

      options[:condition] = options[:condition].to_sym
      assert [:while, :until].include?(options[:condition]), ":condition must be one of :while, :until"

      # For all selectors that don't have the filter_by set, default it to
      # present?
      options[:selectors].each do |sel|
        if not sel.has_key? :filter_by
          sel[:filter_by] = :present?
        end
      end
      return options
    end
  end # module Wait
end # module BrowserModule
end # module LapisLazuli
