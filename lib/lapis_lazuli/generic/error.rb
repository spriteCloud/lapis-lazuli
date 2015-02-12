#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2015 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
module GenericModule

  ##
  # Module with error definitions.
  module Error

    class FindError < RuntimeError
      attr_reader :options
      def initialize(options)
        @options = options
      end

      def message
        "Cannot find element with options: #{@options}"
      end
    end

  end # module Errors
end # module GenericModule
end # module LapisLazuli
