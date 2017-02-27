#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'lapis_lazuli/assertions'

module LapisLazuli

  ##
  # Simple module that helps with function argument parsing.
  module ArgParse
    # Error related options.
    ERROR_OPTIONS = {
      :exception => nil,
      :message => nil,
      :groups => nil,
    }

    ##
    # Parses its arguments, returning an options hash. Use it in a function that
    # just accepts *args to handle both a single hash argument and a list of
    # arguments:
    #
    # Example:
    #   def foo(*args)
    #     defaults = {}
    #     options = parse_args(defaults, "bar", *args)
    #   end
    #
    # The function essentially handles three distinct cases:
    # 1. The arguments are a list:
    #    foo(1, 2)
    #      -> {"bar" => [1, 2]} merged with defaults
    # 2. The first argument is a hash, and it contains "bar":
    #    foo(:x => 1, "bar" => [1, 2])
    #      -> {:x => 1, "bar" => [1, 2]} merged with defaults
    # 3. The first argument is a hash and it does not contain "bar"
    #    foo(:x => 1)
    #      -> {"bar" => [{:x => 1}]} merged with defaults
    #
    # Either option ensures that the second parameter "bar" exists and is an
    # array. Also, all defaults are merged into the options hash.
    def parse_args(defaults, list, *args)
      options = {}

      # If we have a single hash argument, we'll treat it as defaults, and expect
      # the list field to be an Array
      if 1 == args.length and args[0].is_a? Hash
        tmp = args[0]

        if tmp.has_key? list
          # Assert that the list argument is a list. Duh.
          assert tmp[list].is_a?(Array), "Need to provide an Array for #{list}."

          # Merge defaults
          tmp = defaults.merge tmp

          options = tmp
        else
          # No list means that we only have a single argument, which
          # is meant to be the single list item. Any option with defaults
          # must be taken from tmp, if it exists there.
          options = defaults
          tmp.each do |k, v|
            if options.has_key? k
              options[k] = tmp[k]
              tmp.delete(k)
            end
          end
          options[list] = [tmp]
        end

      else
        options = defaults
        options[list] = args
      end

      # Finally, prune options: remove all nil values
      options.each do |k, v|
        if v.nil?
          options.delete k
        end
      end

      return options
    end


    ##
    # Simple way for dealing with an argument that can be either a list, or a
    # single item: we distinguish based on whether the argument responds to 'each'.
    # If the optional 'flatten' parameter is given, nested lists will also be
    # flattened.
    def make_list_from_item(item, flatten = false)
      res = []
      if item.respond_to?('each')
        item.each do |e|
          if flatten
            res << make_list_from_item(e)
          else
            res << e
          end
        end
      else
        res << item
      end
      return res
    end


    ##
    # Using make_list_from_item, apply the logic to all of an array. It
    # effectively flattens nested arrays, if necessary, and does so
    # recursively if the flatten parameter is true.
    def make_list_from_nested(list, flatten = false)
      all = []
      list.each do |item|
        all.concat(make_list_from_item(item, flatten))
      end
      return all
    end

  end # module ArgParse
end # module LapisLazuli
