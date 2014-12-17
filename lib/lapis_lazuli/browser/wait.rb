#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'test/unit/assertions'
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

      condition = options[:condition]
      options.delete(condition)

      # The proc we're waiting for invokes the find_func
      results = []
      has_single = false
      find_proc = lambda { |dummy|
        results = send(find_func.to_sym, options)
        if results.respond_to? :length
          results.length > 0
        else
          has_single = true
          results = [results]
          !!results[0]
        end
      }

      # Call the appropriate condition function.
      err = nil
      begin
        res = Watir::Wait.send(condition, timeout, &find_proc)
      rescue Watir::Wait::TimeoutError => e
        @world.log.debug("Caught timeout: #{e}")
        err = e
      end

      # Error handling
      if not err.nil? and results.empty?
        options[:exception] = err
        @world.error(options)
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
