#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2015 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'lapis_lazuli/assertions'

module LapisLazuli
module GenericModule

  ##
  # Make assertions available as generic module
  module Assertions
    include LapisLazuli::Assertions
  end # module Assertions

end # module GenericModule
end # module LapisLazuli
