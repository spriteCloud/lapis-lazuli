#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/version"
require "lapis_lazuli/world"

module LapisLazuli
  ##
  # Explicitly store the configuration file name
  def self.config_file=(name)
    @config_filename = name
  end

  def self.config_file
    @config_filename
  end

  ##
  # Pass just about everything on to the World class
  def respond_to?(meth)
    return World.instance.respond_to? meth
  end

  def method_missing(meth, *args, &block)
    return World.instance.send(meth.to_s, *args, &block)
  end
end # module LapisLazuli
