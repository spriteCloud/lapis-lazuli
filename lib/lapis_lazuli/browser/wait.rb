#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
module BrowserModule

  ##
  # Wait functionality for Browser
  module Wait
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




  end # module Wait
end # module BrowserModule
end # module LapisLazuli
