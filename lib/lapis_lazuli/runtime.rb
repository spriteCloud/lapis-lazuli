#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
require 'singleton'

module LapisLazuli

  ##
  # Simple singleton class (that therefore lives for the duration of the test's
  # run time for managing objects whose lifetime should also be this long.
  class Runtime
    include Singleton

    def initialize
      require 'pp'
      pp "Singleton creation"
      @objects = {}
    end

    def has?(name)
      return @objects.has_key? name
    end

    def set(world, name, object, destructor = nil)
      if @objects.has_key? name
        pp "got an object already, need to destroy it."
        @objects[name].destroy() # FIXME world
      end

      # Register a finalizer, so we can clean up the proxy again
      ObjectSpace.define_finalizer(self, Runtime.destroy(world, name, destructor))

      @objects[name] = object
    end

    def get(name)
      return @objects[name]
    end


  private
    def self.destroy(world, name, destructor)
      Proc.new do
        require 'pp'
        pp "Trying destructors for #{name}..."
        # If a destructor is given, call that.
        if not destructor.nil?
          return destructor(world)
        end

        # Next, try a has_foo?/foo.destroy combination
        if world.respond_to? "has_#{name}?" and world.respond_to? name
          if world.send("has_#{name}?")
            return world.send(name).destroy(world)
          end
          return false
        end

        # If it only responds to a destroy function, then we can just
        # call that.
        if world.respond_to? name
          return world.send(name).destroy(world)
        end

        # If all else fails, we have to log an error. We can't rely
        # on log existing in world, though...
        message = "No destructor available for #{name}."
        if world.respond_to? :log
          world.log.info(message)
        else
          puts message
        end
      end
    end

  end # class Runtime
end
