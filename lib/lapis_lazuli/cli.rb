#################################################################################
# Copyright 2013,2014 spriteCloud B.V. All rights reserved.
# Author: "Jens Finkhaeuser" <jens@spritecloud.com>
require 'thor'

require 'lapis_lazuli/generators/cucumber'

module LapisLazuli
  class CLI < Thor
    class_option :verbose, :aliases => "-v", :type => :boolean, :default => false, :desc => "Be verbose."

    long_desc <<-LONGDESC
      Creates a cucumber test script directory pre-seeded with common step
      definitions, environment and configuratin support, and all the bells
      and whistles of a proper spriteCloud test setup.
    LONGDESC
    option :force, :aliases => "-f", :type => :boolean, :default => false, :desc => "Always overwrite existing files."
    register(LapisLazuli::Generators::Cucumber, "create", "create PROJECT", "Creates a cucumber project with some common step definitions.")
    register(LapisLazuli::Generators::Cucumber, "update", "update PROJECT", "Updates a project. Alias for 'create'.")
  end
end
