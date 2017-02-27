#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
module LapisLazuli
  ##
  # Simple storage class
  class Storage
    # The name of this storage container
    @name
    @data

    ##
    # Initialize the storage with an optional name
    def initialize(name=nil)
      @name = name
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
    def writeToFile(filename=nil)
      if filename.nil? && @name.nil?
        raise "Need a filename"
      elsif filename.nil?
        filename = "#{@name}.json"
      end

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
        file.puts(@data.to_json)
      }
    end

    ##
    # This will be called during the destruction of the world
    def destroy(world)
      # No data to write
      if @data.keys.length == 0
        world.log.debug("Storage '#{@name}' is empty")
        return
      end

      filename = nil

      # If we have a name
      if !@name.nil?
        # Check the environment for a filename
        env_value = world.env("#{@name}_file", nil)
        if !env_value.nil?
          filename = env_value
        end
      end
      # Otherwise, generate a name
      if filename.nil?
        # Folder to store in
        filename = world.config("storage_dir", ".#{File::SEPARATOR}storage") + File::SEPARATOR

        # Filename
        if @name.nil?
          # Use current timestamp and the object_id of the data
          filename += world.time[:timestamp] + "_" + @data.object_id
        else
          # Use the given name
          filename += @name
        end

        # JSON file extension
        filename += ".json"
      end

      world.log.debug("Writing storage to: #{filename}")
      self.writeToFile(filename)
    end
  end
end
