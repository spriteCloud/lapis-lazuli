#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
module LapisLazuli
  ##
  # Simple storage class
  class Storage
    @data
    def initialize
      @data = {}
    end

    def set(key, value)
      @data[key] = value
    end

    def get(key)
      return @data[key]
    end

    def has?(key)
      return @data.include? key
    end

    ##
    # Write all stored data to file
    def writeToFile(filename)
      # Make storage directory
      dir = File.dirname(filename)
      begin
        Dir.mkdir dir
      rescue SystemCallError => ex
        # Swallow this error; it occurs (amongst other situations) when the
        # directory exists. Checking for an existing directory beforehand is
        # not concurrency safe.
      end

      File.open(filename, 'w') { |file|
        # Write the JSON to the file
        file.write(@data.to_json)
      }
    end

    ##
    # This will be called during the destruction of the world
    def destroy(world)
      filename = world.config("storage_dir", ".#{File::SEPARATOR}storage") +
        File::SEPARATOR +
        world.time[:timestamp] +
        ".json"
      world.log.debug("Writing storage to: #{filename}")
      self.writeToFile(filename)
    end
  end
end
