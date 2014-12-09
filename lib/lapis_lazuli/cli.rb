#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
require 'thor'

require 'lapis_lazuli/generators/cucumber'

module LapisLazuli
  class CLI < Thor
    class_option :verbose, :aliases => "-v", :type => :boolean, :default => false, :desc => "Be verbose."

    long_desc <<-LONGDESC
      Creates/updates a cucumber test script directory pre-seeded with common
      step definitions, environment and configuratin support, and all the bells
      and whistles of a proper spriteCloud test setup.

      The default behaviour is to reference the release gem of the Lapis Lazuli
      version you are using as a dependency of the created/updated project.

      By specifying a github branch, you will instead use that branch of Lapis
      Lazuli as a dependency.
    LONGDESC

    option :branch, :aliases => "-b", :type => :string, :default => nil, :desc => "Specify the github branch of Lapis Lazuli a created/updated project is to use."
    register(LapisLazuli::Generators::Cucumber, "create", "create PROJECT", "Creates a cucumber project with some common step definitions.")
    register(LapisLazuli::Generators::Cucumber, "update", "update PROJECT", "Updates a project. Alias for 'create'.")
  end


end
