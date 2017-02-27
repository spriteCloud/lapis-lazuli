#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
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
      @objects = {}
    end

    ##
    # Number of objects stored in the Runtime
    def length
      return @objects.keys.length
    end

    def has?(name)
      return @objects.has_key? name
    end

    def set(world, name, object, destructor = nil)
      if @objects.has_key? name
        Runtime.destroy(world, name, destructor)
      end

      # Register a finalizer, so we can clean up the proxy again
      ObjectSpace.define_finalizer(self, Runtime.destroy(world, name, destructor))

      @objects[name] = object
    end

    def set_if(world, name, destructor = nil, &block)
      if @objects.has_key? name
        return @objects[name]
      end

      obj = nil
      if !block.nil?
        obj = block.call
      end

      set(world, name, obj, destructor)

      return obj
    end

    ##
    # Remove an object from the Runtime
    def unset(name)
      @objects.delete(name)
    end

    def get(name)
      return @objects[name]
    end


  private
    def self.destroy(world, name, destructor)
      Proc.new do
        # Try to run destroy on the object itself
        obj = Runtime.instance.get(name)

        #world.log.debug("Destroying #{name}")

        # Do not destroy the logger until everything else has been stopped
        if name == :logger and Runtime.instance.length > 1
          #world.log.debug("This is the logger, wait until everything is closed")
          break
        end
        Runtime.instance.unset(name)

        if obj.respond_to?(:destroy)
          obj.send(:destroy, world)
          break
        end
        # If a destructor is given, call that.
        if not destructor.nil?
          return destructor.call(world)
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

        # If the object has stream/socket functions close ends the connection
        if obj.respond_to? :close
          return obj.send(:close)
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
