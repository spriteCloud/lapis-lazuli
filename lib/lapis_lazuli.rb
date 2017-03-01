#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

begin
  require "simplecov"
  require "rubygems"
  spec = Gem::Specification.find_by_name("lapis_lazuli")
  gem_root = "#{spec.gem_dir}#{File::SEPARATOR}"
  coverage_root = "#{gem_root}lib"
  output_dir = "#{Dir.getwd}#{File::SEPARATOR}coverage"
  template_dir = "#{coverage_root}lib#{File::SEPARATOR}lapis_lazuli#{File::SEPARATOR}generators#{File::SEPARATOR}cucumber"

  if ENV['COVERAGE']
    puts "Enabling code coverage for files under '#{coverage_root}';"
    puts "coverage reports get written to '#{output_dir}'."
    SimpleCov.start do
      root(coverage_root)
      coverage_dir(output_dir)
      add_filter(template_dir)
    end
  end
rescue LoadError
  # do nothing
end

require "lapis_lazuli/version"

require "lapis_lazuli/world/config"
require "lapis_lazuli/world/hooks"
require "lapis_lazuli/world/variable"
require "lapis_lazuli/world/error"
require "lapis_lazuli/world/annotate"
require "lapis_lazuli/world/logging"
require "lapis_lazuli/world/browser"
require "lapis_lazuli/world/api"
require "lapis_lazuli/generic/xpath"
require "lapis_lazuli/generic/assertions"


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
  include LapisLazuli::WorldModule::API
  include LapisLazuli::GenericModule::XPath
  include LapisLazuli::GenericModule::Assertions

  ##
  # Export equivalents to cucumber's Before/After functions
  def self.Before(&block)
    LapisLazuli::WorldModule::Hooks.add_hook(:before, block)
  end

  def self.After(&block)
    LapisLazuli::WorldModule::Hooks.add_hook(:after, block)
  end

  def self.Start(&block)
    LapisLazuli::WorldModule::Hooks.add_hook(:start, block)
  end

# FIXME hard to implement; leaving it for now. See issue #13
#  def self.End(&block)
#    LapisLazuli::WorldModule::Hooks.add_hook(:end, block)
#  end
end # module LapisLazuli
