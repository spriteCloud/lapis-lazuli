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
  # Find functionality for LapisLazuli::Browser. Don't use outside of that
  # class.
  module Find
    include LapisLazuli::ArgParse

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
    # - :throw one of true, false. Default is true.
    def find_all(*args)
      # Parse args into options
      options = parse_find_options({}, *args)
      throw_opt, options = do_throw?(options)

      # Find filtered.
      opts, func = find_lambda_filtered(options[:selectors][0])

      # Dispatch the call & handle errors
      return dispatch_call(throw_opt, "Error in find", options, opts, func)
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
    def find(*args)
      # Parse args into options
      options = {
        :pick => :first,
      }
      options = parse_find_options(options, *args)
      pick, options = pick_which?(options)

      # Pick one of the find all results
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
      # Parse args into options
      options = {
        :mode => :match_any,
      }
      options = parse_find_options(options, *args)
      throw_opt, options = do_throw?(options)

      # Find all for the given selectors
      opts, func = multi_find_lambda(options)

      # Dispatch the call & handle errors
      return dispatch_call(throw_opt, "Error in multi_find", options, opts, func)
    end


    ##
    # Same as multi_find_all, but accepts the :pick parameter as find does.
    def multi_find(*args)
      # Parse args into options
      options = {
        :mode => :match_one,
        :pick => :first,
      }
      options = parse_find_options(options, *args)
      pick, options = pick_which?(options)

      # Pick one of the find all results
      return pick_one(pick, multi_find_all(options))
    end


    ##
    # Pick implementation for find and multi_find, but can be used standalone.
    #
    # pick may be one of :first, :last, :random or a numeric index. Returns the
    # element from the collection corresponding to the pick parameter.
    def pick_one(pick, elems)
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
          options[:message] = optional_message("Invalid :pick value #{pick}.", options)
          options[:groups] = ['find', 'pick']
          world.error(options)
        end
      end
    end



  private

    NON_SELECTOR_OPTS = {
      :pick => :first,
      :throw => true,
      :mode => :match_one,
      :error => nil
    }

    ##
    # Uses parse_args to parse find options. Then ensures that for each
    # selector, the expected fields exist.
    def parse_find_options(options, *args)
      # First, parse the arguments into an options hash
      options = ERROR_OPTIONS.merge options
      options = NON_SELECTOR_OPTS.merge options
      options = parse_args(options, :selectors, *args)

      # Verify/sanitize common options
      if options.has_key? :mode
        options[:mode] = options[:mode].to_sym
        assert [:match_all, :match_one, :match_any].include?(options[:mode]), ":mode needs to be one of :match_one, :match_all or :match_any"
      end

      if options.has_key? :pick
        if not options[:pick].is_a? Numeric
          options[:pick] = options[:pick].to_sym
        end
        assert ([:first, :last, :random].include?(options[:pick]) or options[:pick].is_a?(Numeric)), ":pick must be one of :first, :last, :random or a numeric value"
      end

      if options.has_key? :filter_by
        options[:filter_by] = options[:filter_by].to_sym
      end

      # Next, expand all selectors.
      expanded = []
      options[:selectors].each do |sel|
        expanded << expand_selector(sel)
      end
      options[:selectors] = expanded

      # p "-> options: #{options}"
      return options
    end



    ##
    # Expands a selector and verifies it.
    def expand_selector(selector)
      # First convert outer shorthand. Afterwards, selector is guaranteed
      # to be a hash.
      if selector.is_a? String
        selector = {:element => selector}
      elsif selector.is_a? Symbol
        selector = {:like => selector}
      end

      # Now ensure the :like parameter is a full hash
      if selector.include? :like
        like_opts = selector[:like]
        # Convert array shorthand to full Hash
        if like_opts.is_a? Array and like_opts.length >= 3
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

        selector[:like] = like_opts
        if not like_opts.has_key? :element
          selector[:message] = optional_message("Like selector are missing the :element key.", selector)
          selector[:groups] = ['find', 'selector']
          world.error(selector)
        end
      end

      return selector
    end



    ##
    # Return a lambda function that can be executed to find an element.
    # find(), multi_find(), wait() and multi_wait() use this function,
    # so look there for documentation.
    #
    # There are a number of different modes, triggered by the presence or
    # absence of particular parameters. Note that the parameters passed
    # here must have been passed through parse_find_options() before.
    #
    # That said:
    #   - The presence of :like will construct an XPath selector from the
    #     sub-fields :element, :attribute and :include, finding the given
    #     element where the given attribute includes the given text. Note
    #     that the special attribute :text is interpreted as meaning the
    #     text content of the element.
    #
    def find_lambda(options)
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

      # require 'pp'
      # pp "find options: #{options}, has context: #{has_context}"

      # Make {:html => x} a shortcut for {:html => {:text => x}}, but only
      # if it's the only option.
      if options.has_key? :html and 1 == options.length
        if options[:html].is_a? String or options[:html].is_a? Regexp
          options[:html] = { :text => options[:html] }
        end
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
        if not context.respond_to? function_name
          next
        end

        # If the value is a hash use it as arguments for this function
        if value.is_a? Hash
          return options, lambda {
            context.send(function_name, value)
          }
        else
          # Find it based on name, id or text
          str = value.to_s
          return options, lambda {
            xpath = "#{'.' if has_context}//*[@name='#{str}' or @id='#{str}' or text()='#{str}']"
            context.send(
              function_name,
              :xpath => xpath
            )
          }
        end
      end

      # Finally, if no field is given, we'll just pass on everything to
      # the elements function as-is, in case there's a regular Watir selector
      # in it.
      return options, lambda {
        elems = context.elements(options)
        # XXX Hack for firefox webdriver. When the given options return no
        #     matches, elems.length would be 0, elems.each would not iterate
        #     over anything, but elems[0] is the top-level HTML element, etc.
        if elems.length <= 0
          elems = []
        end
        elems
      }
    end


    ##
    # Similar to find_lambda, but filters the returned elements by the given
    # :filter_by function (defaults to :present?).
    def find_lambda_filtered(options)
      options = options.dup

      filter_by = options.fetch(:filter_by, :present?)
      options.delete(:filter_by)
      options, inner = find_lambda(options)

      # Wrap into filter function
      return options, lambda {
        elems = inner.call

        # XXX See similar comment in find_lambda()
        if elems.length <= 0
          elems = []
        end

        # If we have elements and want them filtered, deal with that now.
        if elems and not filter_by.nil?
          elems = elems.find_all { |elem|
            elem.send(filter_by)
          }
        end
        elems
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
        context.elements(
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
      when :match_all, :match_any
        return options, lambda {
          all = []
          lambdas.each do |func|
            res = func.call
            if 0 == res.length and options[:mode] == :match_all
              all = []
              break
            end
            res.each do |e|
              all << e
            end
          end
          all
        }
      when :match_one
        return options, lambda {
          res = []
          lambdas.each do |func|
            res = func.call
            # world.log.debug("Got: #{res}")
            if res.length > 0
              break
            end
          end
          res
        }
      else
        options[:message] = optional_message("Invalid mode '#{options[:mode]}' provided to multi_find_all.", options)
        options[:groups] = ['find', 'multi', 'mode']
        world.error(options)
      end
    end


    def do_throw?(options)
      ret = options.fetch(:throw, NON_SELECTOR_OPTS[:throw])
      options.delete(:throw)
      return ret, options
    end


    def pick_which?(options)
      ret = options.fetch(:pick, NON_SELECTOR_OPTS[:pick])
      options.delete(:pick)
      return ret, options
    end


    def optional_message(message, opts)
      if opts.has_key? :message
        return opts[:message]
      end
      return message
    end


    def dispatch_call(throw_opt, message, selectors, opts, func)
      begin
        ret = func.call

        if throw_opt and (ret.nil? or ret.length <= 0)
          msg = "Cannot find elements with selectors: "
          if selectors[:selectors].length < 2
            msg += "#{selectors[:selectors]}\n"
          else
            msg += "\n"
            selectors[:selectors].each do |s|
              msg += "- #{s} \n"
            end
          end
          selectors.delete(:selectors)
          msg += "With the options: #{selectors}"
          raise msg
        end

        return ret
      rescue RuntimeError => err
        opts[:message] = optional_message(message, selectors)
        opts[:exception] = err
        world.error(opts)
      end
    end
  end # module Find
end # module BrowserModule
end # module LapisLazuli
