#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
  ##
  # Module with configuration loading related functions
  #
  # Defines and uses:
  #   @config - internal configuration representation
  #   @env    - loaded/detected config/test environment
  module Config

    ##
    # Loads a config based on a filename
    #
    # Supports: YML, JSON
    #
    # Example:
    #   ENV['TEST_ENV'] = 'production'
    #   load_config("config/config.yml")
    #
    # Will try to load the following files:
    # - config/config-production.yml
    # - config/config-debug.yml
    # - config/config-test.yml
    # - config/config-local.yml
    # - config/config.yml
    def load_config(config_name)
      # Split the filename
      ext = File.extname(config_name)
      dir, filename = File.split(config_name)
      basename = File.basename(filename, ext)

      # What are the suffixes to check
      suffixes = [
        "debug",
        "test",
        "local"
      ]

      # Do we have an environment
      if not @env.nil?
        # Add it to the suffixes
        suffixes.unshift(@env)
      end

      # Turn suffixes into files to try
      files = []
      suffixes.each do |suffix|
        files << "#{dir}/#{basename}-#{suffix}#{ext}"
      end
      files << config_name

      # Try all files in order
      files.each do |file| 
        begin
          # Try to load a config file
          return self.load_config_from_file(file)
        rescue
          # Do nothing, load the next file
        end
      end
    end


    ##
    # Loads a config file
    #
    # Supports: YML, JSON
    #
    # Throws errors if:
    # - Config file isn't readable
    # - Environment doesn't exist in config
    # - Default environment not set in config if no environment is set
    def load_config_from_file(filename)
      # Try to load the file from disk
      begin
        # Determine the extension
        ext = File.extname(filename)
        # Use the correct loader
        if ext == ".yml"
          @config = YAML.load_file(filename)
        elsif ext == ".json"
          json = File.read(filename)
          @config = JSON.parse(json)
        end
      rescue RuntimeError => err
        # Can't help you
        raise "Error loading file: #{filename} #{err}"
      end

      # If we have an environment this config should have it
      if not @env.nil? and not self.has_config?(@env)
        raise "Environment doesn't exist in config file"
      end

      # If we don't have one then load the default
      if @env.nil? and self.has_config?("default_env")
        tmp = self.config("default_env")
        if self.has_config?(tmp)
          @env = tmp
        else
          raise "Default environment not present in config file"
        end
      end
    end



    ##
    # Does the config have a variable?
    # Uses config and catches any errors it raises
    def has_config?(variable)
        begin
          value = self.config(variable)
          return (not value.nil?)
        rescue
          return false
        end
    end

    ##
    # Get the configuration from the config,
    # uses a dot seperator for object traversing
    #
    # Example:
    # ll.config("test.google.url") => "www.google.com"
    #
    # Raises error if traversing the object is impossible
    def config(variable=false, default=nil)
      # No variable given? Return the entire object.
      result = @config
      if not variable
        return result
      end

      # Environment variables for known options override the option.
      if CONFIG_OPTIONS.has_key? variable
        env = variable.upcase
        if ENV.has_key? env
          return ENV[env]
        end
      end

      # Otherwise try to find it in the configuration object
      variable.split(".").each do |part|
        if default.nil? and result.nil?
          raise "Unknown configuration variable '#{variable}' and no default given!"
        end
        result = result[part]
      end

      if default.nil? and result.nil?
        if CONFIG_OPTIONS.has_key? variable
          return CONFIG_OPTIONS[variable][0]
        else
          raise "Unknown configuration variable '#{variable}' and no default given!"
        end
      else
        return result || default
      end
    end

    ##
    # Does the environment have a certain config variable
    def has_env?(variable)
      if @env.nil?
        return false
      end
      return self.has_config?("#{@env}.#{variable}")
    end

    ##
    # Get a environment variable from the config file
    # Alias for ll.config(ll.env + "." + variable)
    def env(variable=false, default=nil)
      if not variable
        return self.config(@env)
      end
      return self.config("#{@env}.#{variable}",default)
    end

    ##
    # Checks if a variabl exist in the env or config
    def has_env_or_config?(variable)
      return self.has_env?(variable) || self.has_config?(variable)
    end

    ##
    # Get a variable from the config
    # First checks the environment section, before it checks the global part
    def env_or_config(variable, default=nil)
      if self.has_env?(variable)
        return self.env(variable, default)
      elsif self.has_config?(variable)
        return self.config(variable, default)
      else
        return nil
      end
    end




  end # module Config
end # module LapisLazuli
