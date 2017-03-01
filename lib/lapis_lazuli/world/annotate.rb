#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'json'

require 'lapis_lazuli/argparse'

module LapisLazuli
module WorldModule
  ##
  # Module with annotation related functionality
  #
  # Annotations are embedded into the report via cucumber's embed function, and
  # that means they're embedded at the step level.
  #
  # They're also stored at scenario scope, so one step in a scenario can access
  # annotations made in another step.
  module Annotate

    include LapisLazuli::ArgParse

    def annotate(*args)
      @annotations ||= {}

      scope = scenario.scope(true) || 'items'
      stuff = parse_args({}, scope, *args)

      for_scope = @annotations.fetch(scope, [])
      for_scope << stuff[scope]
      @annotations[scope] = for_scope

      if self.respond_to? "embed"
        embed(JSON.generate(stuff), 'application/json')
      end
    end

    def annotations
      @annotations
    end
  end # module Annotate
end # module WorldModule
end # module LapisLazuli
