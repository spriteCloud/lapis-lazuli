#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
module LapisLazuli
module GenericModule

  ##
  # Helper functions for XPath composition
  module XPath


    ##
    # Return an xpath contains clause for e.g. checking wether an element's
    # class attribute node contains a string. The optional third parameter
    # determines how substrings are separated in the attribute node; the
    # default is space for matching class names.
    # Note that enclosing [ and ] are not included in the return value; this
    # lets you more easily use and()/or()/not() operators.
    def xp_contains(node, needle, separator = ' ')
      contains = "contains(concat('#{separator}', normalize-space(#{node}), '#{separator}'), '#{separator}#{needle}#{separator}')"
      return contains
    end

    ##
    # Constructs xpath and clause
    def xp_and(first, second)
      return "(#{first} and #{second})"
    end

    ##
    # Constructs xpath or clause
    def xp_or(first, second)
      return "(#{first} or #{second})"
    end

    ##
    # Constructs xpath or clause
    def xp_not(expr)
      return "not(#{expr})"
    end


  end # module XPath
end # module GenericModule
end # module LapisLazuli
