#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'test/unit/assertions'

module LapisLazuli

  ##
  # Find functionality for LapisLazuli::Browser. Don't use outside of that
  # class.
  module Find

    ##
    # Finds all elements corresponding to some specification; the supported
    # specifications include the ones accepted by Watir::Browser.elements.
    #
    # Possible specifications are:
    # - Watir specifications, e.g. { :tag_name => 'a', ... }
    # - An alternative to the Watir specifications:
    #   { :a => { :id => /some-id/ } } <=> { :tag_name => 'a', :id => /some-id/ }
    #   Note that the value can be an empty hash, e.g. { :a => {} }
    #   This method uses Watir selectors.
    # - A shortcut version searching for a tag by name, id or content:
    #   { :a => 'name-or-id-or-content' }
    #   This method uses XPath.
    # - A like specifcation. The value of :like is a hash, which must at least
    #   contain an :element name; in addition, an optional :attribute and
    #   :include field further filters the results.
    #   { :like => {:element => 'a', :attribute => 'class', :include => 'foo' }}
    #   This method uses XPath.
    # - A shorthand for the above using an array that's interpreted to contain
    #   :element, :attribute and :include in order.
    #   { :like => ['a', 'class', 'foo'] }
    #   This method also uses XPath.
    #
    # In addition to the above, you can include the following parameters:
    # - :filter_by expects a symbol that the elements respond to; if calling
    #   the method returns true, the element is returned, otherwise it is
    #   ignored. Use e.g. { :filter_by => :present? }
    def find_all(options)
      opts, func = find_lambda_filtered(options)

      begin
        return func.call
      rescue RuntimeError => err
        opts[:message] = "Error in find"
        opts[:exception] = err
        @ll.error(opts)
      end
    end


    ##
    # Same as find_all, but returns only one element.
    #
    # The function supports an additional parameter :pick that can be one of
    # :first, :last or :random, or a numeric value.
    #
    # The parameter determines whether the first, last or a random element from
    # the find_all result set is returned. If a numeric value is given, the nth
    # element is returned.
    #
    # The default for :pick is :first
    def find(options)
      options = parse_find_options(options)

      pick = options.fetch(:pick, "first")
      options.delete(:pick)

      return pick_one(pick, find_all(options))
    end


    ##
    # Same as find_all, but accepts an array of selectors.
    #
    # The function has two modes:
    # 1. It either tries to find a match for every selector, or
    # 2. It tries to find a single match from all selectors.
    #
    # The mode is specified with the optional :mode parameter, which can be
    # one of :match_all or :match_any. The default mode is :match_any.
    #
    # Note that if you specify the :mode, you can't simultaneously pass a list
    # of selectors easily, e.g. the following does not parse:
    #
    #   multi_find_all(:mode => :match_all, selector1, selector2)
    #
    # Instead use:
    #
    #   multi_find_all(:mode => :match_all, :selectors => [selector1, selector2])
    #
    # However, using the default mode, you can simplify it all:
    #
    #   multi_find_all(selector1, selector2)
    def multi_find_all(*args)
      options = parse_multi_find_options(*args)

      options, func = multi_find_lambda(options)

      begin
        return func.call
      rescue RuntimeError => err
        opts[:message] = "Error in multi_find"
        opts[:exception] = err
        @ll.error(opts)
      end
    end


    ##
    # Same as multi_find_all, but accepts the :pick parameter as find does.
    def multi_find(*args)
      options = parse_multi_find_options(*args)

      # Extract pick option
      pick = options.fetch(:pick, "first").to_sym
      options.delete(:pick)

      options, func = multi_find_lambda(options)

      begin
        return pick_one(pick, func.call)
      rescue RuntimeError => err
        opts[:message] = "Error in multi_find"
        opts[:exception] = err
        @ll.error(opts)
      end
    end

  private

    ##
    # Parse extra options in multi_find options
    def parse_multi_find_options(*args)
      # Default options
      options = {
        :mode => :match_one
      }

      # If we have a single hash argument, we'll treat it as options, and expect
      # the :selectors field.
      if 1 == args.length and args[0].is_a? Hash
        opts = args[0]
        options.each do |k, v|
          if not opts.has_key? k
            opts[k] = v
          end
        end

        assert opts.has_key?(:selectors) and opts[:selectors].is_a? Array, "Need to provide a list of element selectors."
        options = opts
      else
        options[:selectors] = args
      end

      # Ensure correct types
      options[:mode] = options[:mode].to_sym

      return options
    end

    ##
    # Convert all shortcut options to a full options hash
    def parse_find_options(options)
      # First convert outer shorthand. Afterwards, options is guaranteed
      # to be a hash.
      if options.is_a? String
        options = {:element => options}
      elsif options.is_a? Symbol
        options = {:like => options}
      elsif options.is_a? Array
        options = options.map do |setting|
          parse_find_options setting
        end
      end

      # Now ensure the :like parameter is a full hash
      if options.include? :like
        like_opts = options[:like]
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

        options[:like] = like_opts
        if not like_opts.has_key? :element
          options[:message] = "Like options are missing the :element key."
          options[:groups] = ['find', 'options']
          @ll.error(options)
        end
      end

      return options
    end



    ##
    # Return a lambda function that can be executed to find an element.
    # find(), multi_find(), wait() and multi_wait() use this function,
    # so look there for documentation.
    #
    # There are a number of different modes, triggered by the presence or
    # absence of particular parameters. Note that the parameters passed
    # here are passed through parse_find_options() before being evaluated:
    # that function expands shorthand options to a full hash.
    #
    # That said:
    #   - The presence of :like will construct an XPath selector from the
    #     sub-fields :element, :attribute and :include, finding the given
    #     element where the given attribute includes the given text. Note
    #     that the special attribute :text is interpreted as meaning the
    #     text content of the element.
    #
    def find_lambda(options)
      # Parse options
      options = parse_find_options options

      # A context is starting position for the search
      # Example:
      #  parent = ll.browser.find(:div => "some_parent")
      #  ll.browser.find(:a => "some_link", :context => parent)
      context = @browser
      has_context = false
      if options.has_key? :context
        context = options[:context]
        options.delete(:context)
        has_context = true
      end

      # Do we have :like options? Create an appropriate lambda
      if options.has_key? :like
        return find_lambda_like(context, has_context, options)
      end

      # If one of the options keys is a method of the context, then we'll
      # invoke that method. The options value is passed to the method if it is
      # a hash; if it's anything else, it's assumed to be a tag name, id or text
      # contents we'll find with XPath.
      options.each do |key, value|
        # Find the one the browser responds to
        # Example: text_fields or buttons
        function_name = "#{key.to_s}s"
        if context.respond_to? function_name
          # If the value is a hash use it as arguments for this function
          if value.is_a? Hash
            return options, lambda {
              return context.send(function_name, value)
            }
          else
            # Find it based on name, id or text
            str = value.to_s
            return options, lambda {
              return context.send(
                function_name,
                :xpath,
                "#{'.' if has_context}//*[@name='#{str}' or @id='#{str}' or text()='#{str}']"
              )
            }
          end
        end
      end

      # Finally, if no field is given, we'll just pass on everything to
      # the elements function as-is, in case there's a regular Watir selector
      # in it.
      return options, lambda {
        return context.elements(options)
      }
    end


    ##
    # Similar to find_lambda, but filters the returned elements by the given
    # :filter_by function (defaults to :present?).
    def find_lambda_filtered(options)
      options = parse_find_options(options)

      filter_by = options.fetch(:filter_by, nil)
      options.delete(:filter_by)

      options, inner = find_lambda(options)

      # No filter? Then don't do anything special
      if filter_by.nil?
        return options, inner
      end

      # Wrap into filter function
      return options, lambda {
        elems = inner.call
        if not elems
          return nil
        end
        return elems.find_all { |elem|
          elem.send(filter_by)
        }
      }
    end


    ##
    # Component of find_lambda; returns the lambda for when :like
    # options are present.
    def find_lambda_like(context, has_context, options)
      # Shortcuts
      like_opts = options[:like]

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
        xpath = "#{xpath}[#{xp_contains(attribute, like_opts[:include], '')}]"
      end

      # Create the XPath query
      return options, lambda {
        return context.elements(
          :xpath,
          xpath
        )
      }
    end


    ##
    # The heart of multi_find_all, but returns a lambda.
    #
    # This function exists for easier implementation of the wait functions.
    def multi_find_lambda(options)
      # Collect the lambdas for all selectors
      lambdas = []
      options[:selectors].each do |selector|
        s, func = find_lambda_filtered(selector)
        lambdas << func
      end

      # Depending on mode, we need to execute something slightly different
      case options[:mode]
      when :match_all
        return options, lambda {
          all = []
          lambdas.each do |func|
            res = func.call
            res.each do |e|
              all << e
            end
          end
          return all
        }
      when :match_one
        return options, lambda {
          lambdas.each do |func|
            res = func.call
            # @ll.log.debug("Got: #{res}")
            if res.length > 0
              return res
            end
          end
          return []
        }
      else
        options[:message] = "Invalid mode '#{options[:mode]}' provided to multi_find_all."
        options[:groups] = ['find', 'multi', 'mode']
        @ll.error(options)
      end
    end


    ##
    # Pick implementation for find and multi_find
    def pick_one(pick, elems)
      if pick.is_a? String
        pick = pick.to_sym
      end

      case pick
      when :first
        return elems.first
      when :last
        return elems.last
      when :random
        return elems.to_a.shuffle.first
      else
        if pick.is_a? Numeric
          return elems[pick.to_i]
        else
          options[:message] = "Invalid :pick value #{pick}."
          options[:groups] = ['find', 'pick']
          @ll.error(options)
        end
      end
    end

  end # module Find
end # module LapisLazuli
