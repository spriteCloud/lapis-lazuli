#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/version"

require "lapis_lazuli/world/config"
require "lapis_lazuli/world/hooks"
require "lapis_lazuli/world/variable"
require "lapis_lazuli/world/error"
require "lapis_lazuli/world/annotate"
require "lapis_lazuli/world/logging"
require "lapis_lazuli/world/browser"
require "lapis_lazuli/generic/xpath"


module LapisLazuli
  ##
  # Includes all the functionality from the following modules.
  include LapisLazuli::WorldModule::Config
  include LapisLazuli::WorldModule::Hooks
  include LapisLazuli::WorldModule::Variable
  include LapisLazuli::WorldModule::Error
  include LapisLazuli::WorldModule::Annotate
  include LapisLazuli::WorldModule::Logging
  include LapisLazuli::WorldModule::Browser
  include LapisLazuli::GenericModule::XPath
end # module LapisLazuli
