#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/options"

module LapisLazuli
module WorldModule
  ##
  # Module with configuration loading related functions
  #
  # Manages the following:
  #   @config          - internal configuration representation
  #   config_file      - Needs to be set before config can be accessed.
  #   @env             - loaded/detected config/test environment
  module Config
    ##
    # Explicitly store the configuration file name.
    module ClassMethods
      def config_file=(name)
        @config_file = name
      end

      def config_file
        return @config_file || "config/config.yml"
      end
    end
    extend ClassMethods


    ##
    # The configuration is not a singleton, precisely, but it does not need to
    # be created more than once. Note that explicitly calling load_config will
    # still work to overwrite an existing configuration.
    def init
      # Guard against doing this more than once.
      if not @config.nil?
        return
      end

      if Config.config_file.nil?
        raise "No configuration file provided, set LapisLazuli::WorldModule::Config.config_file"
      end

      load_config(Config.config_file)

      if @config.nil?
        raise "Could not load configuration."
      end
    end


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

      if ENV["TEST_ENV"]
        @env = ENV["TEST_ENV"]
      end

      # Do we have an environment
      if not @env.nil?
        # Add it to the suffixes
        suffixes.unshift(@env)
      end

      # Turn suffixes into files to try
      files = []
      suffixes.each do |suffix|
        files << "#{dir}#{File::SEPARATOR}#{basename}-#{suffix}#{ext}"
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
      # Make sure the configured configuration is loaded, if possible
      init

        begin
          value = self.config(variable)
          return (not value.nil?)
        rescue RuntimeError => err
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
      # Make sure the configured configuration is loaded, if possible
      init

      # No variable given? Return the entire object.
      result = @config
      if not variable
        return result
      end

      # Environment variables for known options override the option.
      if CONFIG_OPTIONS.has_key? variable
        var = variable.upcase
        if ENV.has_key? var
          return ENV[var]
        end
      end

      # Otherwise try to find it in the configuration object
      variable.split(".").each do |part|
        if default.nil? and result.nil?
          raise "Unknown configuration variable '#{variable}' and no default given!"
        end
        break if result.nil?
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
      # Make sure the configured configuration is loaded, if possible
      init

      if @env.nil?
        return false
      end
      return self.has_config?("#{@env}.#{variable}")
    end

    ##
    # Returns current environment
    def current_env
      init
      
      return @env
    end

    ##
    # Get a environment variable from the config file
    # Alias for ll.config(ll.env + "." + variable)
    def env(variable=false, default=nil)
      # Make sure the configured configuration is loaded, if possible
      init

      if not variable
        return self.config(@env)
      end

      # Environment variables for known options override environment specific
      # options, too
      if CONFIG_OPTIONS.has_key? variable
        var = variable.upcase
        if ENV.has_key? var
          return ENV[var]
        end
      end

      return self.config("#{@env}.#{variable}",default)
    end

    ##
    # Checks if a variabl exist in the env or config
    def has_env_or_config?(variable)
      # Make sure the configured configuration is loaded, if possible
      init

      return self.has_env?(variable) || self.has_config?(variable)
    end

    ##
    # Get a variable from the config
    # First checks the environment section, before it checks the global part
    def env_or_config(variable, default=nil)
      # Make sure the configured configuration is loaded, if possible
      init

      if self.has_env?(variable)
        return self.env(variable, default)
      elsif self.has_config?(variable)
        return self.config(variable, default)
      else
        return nil
      end
    end




  end # module Config
end # module WorldModule
end # module LapisLazuli
