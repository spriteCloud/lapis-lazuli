#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2015 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
#
module LapisLazuli
  ##
  # Convenience module for dealing with aspects of the cucumber AST. From
  # version 1.3.x to version 2.0.x, some changes were introduced here.
  module Ast
    ##
    # Return a unique and human parsable ID for scenarios
    def scenario_id(scenario)
      [scenario.id]
    end

  end # module Ast
end # module LapisLazuli
