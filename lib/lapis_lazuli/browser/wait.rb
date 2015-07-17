#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2015 spriteCloud B.V. and other LapisLazuli contributors.
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

      # The easiest way to deal with find's new :throw policy is to set it to
      # false.
      options[:throw] = false

      # pp "got options: #{options}"

      # The proc we're waiting for invokes the find_func
      results = []
      has_single = false
      find_proc = lambda { |dummy|
        res = false
        err = nil
        retries.times do
          begin
            opts = Marshal.load(Marshal.dump(options))
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
            err = e
          end
          # Retry
        end

        # Raise the error if the retries didn't suffice
        if not err.nil? and not res
          raise err, "Tried #{retries} times, but got: #{err.message}", err.backtrace
        end

        # Return the results!
        res
      }

      # Call the appropriate condition function.
      err = nil
      begin
        res = Watir::Wait.send(condition, timeout, &find_proc)
      rescue Watir::Wait::TimeoutError => e
        world.log.debug("Caught timeout: #{e}")
        err = e
      end

      # Filter out any nil results
      filter_results = results.select {|i| not i.nil?}
      # Error handling
      if not err.nil?
        options[:exception] = err
        world.error(options)
      end

      # Set if the underlying find function returns single results
      if has_single
        return results[0]
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
