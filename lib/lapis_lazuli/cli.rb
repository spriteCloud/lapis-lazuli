#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
require 'thor'

require 'lapis_lazuli/generators/cucumber'
require 'lapis_lazuli/options'
require 'lapis_lazuli/placeholders'

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


    desc "config", "Describe how LapisLazuli configuration works."
    def config 
      STDOUT.write <<-INTRO
LapisLazuli searches for configuration files in the `config' subdirectory of
the current working directory, taking the stated test environment into
consideration.

Example:
  ENV['TEST_ENV'] = 'production'
  load_config("config/config.yml")

Will try to load the following files, in order:
  - config/config-production.yml
  - config/config-debug.yml
  - config/config-test.yml
  - config/config-local.yml
  - config/config.yml

The first configuration file in the list that is found will be loaded, and its
contents become available via the configuraiton functions.

Supported configuration formats and file name extensions are:
  .yml  - YAML file
  .json - JSON file

In addition to environment-specific configuration files, LapisLazuli supports
the concept of test environments within a single file, where environments are
just top-level keys, e.g.:

  production:
    - config for the production environment

  development:
    - config for the development environment

The configuration files can contain any configuration options, but a few are
interpreted by LapisLazuli. Note that instead of specifying these supported
options in the configuraiton file, you may also provide them in the environment
(convert option name to upper case). Environment variables override the
configuration file contents.

INTRO
      STDOUT.flush

      LapisLazuli::CONFIG_OPTIONS.each do |option, value|
        printf "%22s\n", option

        display_default = value[0]
        if display_default.nil?
          display_default = "No default."
        else
          display_default = "Defaults to '#{display_default}'."
        end
        printf "                 #{display_default}\n"
        printf "                 #{value[1]}\n\n"

      end
    end



    desc "placeholders", "Display placeholders managed by WorldModule::Variable."
    def placeholders
      STDOUT.write <<-INTRO
The following are placeholders to use with WorldModule::Variable's functions
as managed by this version of LapisLazuli.

INTRO
      STDOUT.flush

      LapisLazuli::PLACEHOLDERS.each do |option, value|
        printf "%22s - %s\n", option, value[1]
      end
    end
  end
end
