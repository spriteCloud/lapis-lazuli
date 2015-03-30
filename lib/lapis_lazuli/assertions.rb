#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2015 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'minitest'
require 'minitest/assertions'

module LapisLazuli
  ##
  # Module exists solely to not have require/include statements all over
  # the code referencing an external library.
  module Assertions
    include Minitest::Assertions

    def assertions
      @assertions ||= 0
    end

    def assertions=(value)
      @assertions = value
    end
  end # module Assertions
end # module LapisLazuli
