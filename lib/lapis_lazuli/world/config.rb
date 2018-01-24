#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/options"
require "lapis_lazuli/storage"
require "lapis_lazuli/runtime"
require 'deep_merge'

module LapisLazuli
  module WorldModule
    ##
    # Module with configuration loading related functions
    #
    # Manages the following:
    #   @config          - internal configuration representation
    #   config_files     - Needs to be set before config can be accessed.
    #   @env             - loaded/detected config/test environment
    module Config
      ##
      # Explicitly store the configuration file name.
      module ClassMethods

        # <b>DEPRECATED:</b> Please use <tt>add_config</tt> instead.
        def config_file=(name)
          warn "[DEPRECATION] `config_file = name` is deprecated.  Please use `add_config(file)` instead."
          add_config(name)
        end

        # <b>DEPRECATED:</b> Please use <tt>config_files</tt> instead.
        def config_file
          warn "[DEPRECATION] `config_file` is deprecated.  Please use `config_files` instead."
          return config_files
        end

        def add_config(file)
          @config_files = [] if @config_files.nil?
          @config_files.push(file)
        end

        def config_files
          return @config_files || ["config/config.yml"]
        end
      end
      extend ClassMethods


      ##
      # The configuration is not a singleton, precisely, but it does not need to
      # be created more than once. Note that explicitly calling load_config will
      # still work to overwrite an existing configuration.
      def init
        # Guard against doing this more than once.
        unless @config.nil?
          return
        end

        if Config.config_files.nil?
          raise "No configuration file provided, set LapisLazuli::WorldModule::Config.config_files"
        end

        load_config(Config.config_files)
        # In case there was no config file found an empty @config needs to be set to prevent infinite looping.
        if @config.nil?
          warn 'Unable to find a configuration file, defaulting to empty config.yml.'
          @config = {}
        end

        @metadata = Runtime.instance.set_if(self, :metadata) do
          log.debug "Creating metadata storage"
          Storage.new("metadata")
        end
      end

      def metadata
        if @metadata.nil?
          raise "No metadata available"
        end
        return @metadata
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
      #
      # Throws errors if:
      # - Config file isn't readable
      # - Environment doesn't exist in config
      # - Default environment not set in config if no environment is set
      def load_config(config_names)
        # Go trough each config_name
        config_names.each do |config_name|
          files = []
          # Split the filename
          ext = File.extname(config_name)
          dir, filename = File.split(config_name)
          basename = File.basename(filename, ext)

          # What are the suffixes to check
          suffixes = %w(debug test local)

          if ENV["TEST_ENV"]
            @env = ENV["TEST_ENV"]
          end

          # Do we have an environment
          unless @env.nil?
            # Add it to the suffixes
            suffixes.unshift(@env)
          end

          # Turn suffixes into files to try
          suffixes.each do |suffix|
            files << "#{dir}#{File::SEPARATOR}#{basename}-#{suffix}#{ext}"
          end
          files << config_name
          # Try all files in order
          files.each do |file|
            # Check if files exist
            if File.file?(file)
              begin
                # Try to load a config file
                self.add_config_from_file(file)
                break
              rescue Exception => e
                raise e
              end
            end
          end
        end
        # If we have an environment, the config should contain it
        if not @env.nil? and not self.has_config?(@env)
          raise "Environment `#{@env}` doesn't exist in any of the config files"
        end

        # If we don't have one then load the default
        if @env.nil? and self.has_config?("default_env")
          tmp = self.config("default_env")
          if self.has_config?(tmp)
            @env = tmp
            ENV['TEST_ENV'] = tmp
          else
            raise "Default environment not present in any of the config files"
          end
        end
      end


      ##
      # Loads a config file
      #
      # Supports: YML, JSON
      #
      # Adds the possibility to merge multiple config files.
      def add_config_from_file(filename)
        @config = {} if @config.nil?
        # Add the data to the global config
        @config.deep_merge! get_config_from_file(filename)
      end

      # returns the data that's loaded from a config file.
      # Supports YAML and JSON
      def get_config_from_file(filename)
        # Try to load the file from disk
        begin
          # Determine the extension
          ext = File.extname(filename)
          # Use the correct loader
          if ext == ".yml"
            data = YAML.load_file(filename)
          elsif ext == ".json"
            json = File.read(filename)
            data = JSON.parse(json)
          end
        rescue Exception => e
          raise "Error loading file: #{filename} #{e}"
        end

        # Fix up empty files
        if data.nil? or data == false
          warn "Could not load configuration from '#{Config.config_files}'; it might be empty or malformed."
          data = {}
        end
        return data
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
      def config(variable=false, default=(no_default_set=true; nil))
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
          if no_default_set == true && result.nil?
            raise "Unknown configuration variable '#{variable}' and no default given!"
          end
          break if result.nil?
          begin
            result = result[part]
          rescue TypeError, NoMethodError => ex
            warn "Could not read configuration variable #{variable}: #{ex}"
            break
          end
        end

        if default.nil? and result.nil?
          if CONFIG_OPTIONS.has_key? variable
            return CONFIG_OPTIONS[variable][0]
          elsif no_default_set == true
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
      def env(variable=false, default=(no_default_set=true; nil))
        # Make sure the configured configuration is loaded, if possible
        init

        if not variable
          return self.config(@env)
        end

        # Environment variables for known options override environment specific
        # options, too
        env_var = var_from_env(variable, default)
        if env_var != default
          return env_var
        end

        result = self.config("#{@env}.#{variable}", default)

        if no_default_set == true and result.nil?
          raise "Unknown environment variable '#{@env}.#{variable}' and no default given"
        end

        return result

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
      def env_or_config(variable, default=(no_default_set=true; nil))
        # Make sure the configured configuration is loaded, if possible
        init

        # Environment variables for known options override environment specific
        # options, too
        env_var = var_from_env(variable, default)
        if env_var != default
          return env_var
        end

        if self.has_env?(variable)
          return self.env(variable)
        elsif self.has_config?(variable)
          return self.config(variable)
        else
          if no_default_set == true
            raise "Unknown environment or configuration variable '(#{@env}.)#{variable}' and no default given"
          end
          return default
        end
      end

      def var_from_env(var, default=nil)
        # Simple solution for single depth variables like "browser"
        if ENV.has_key? var
          return ENV[var]
        end

        value = default

        # Variables like:
        #  var_from_env("remote.url","http://test.test")
        if var.is_a? String and
          not default.is_a? Hash

          # Env variables cannot contain a . replace them by _
          key_wanted = var.gsub(".", "__")

          # Do a case insensitive compare
          ENV.keys.each do |key|
            if key.casecmp(key_wanted) == 0
              value = ENV[key]
              break
            end
          end

          # Environment:
          #   REMOTE__USER=test
          #   REMOTE__PASS=test
          #   REMOTE__PROXY__HTTP=http://test.com
          #
          # Call:
          #   var_from_env("remote",{})
          #
          # Result:
          #   {"USER" => "test",
          #    "PASS" => "test",
          #    "proxy" => {"HTTP" => "http://test.con"}}
        elsif default.is_a? Hash
          # Env variables cannot contain a . replace them by _
          key_wanted = var.gsub(".", "__")
          # Use a regular expression starting with the wanted key
          rgx = Regexp.new("^#{key_wanted}", "i")

          result = {}
          # For each key check if it matched the regexp
          ENV.keys.each do |key|
            if (key =~ rgx) == 0
              tmp = result
              # Remove start and split into parts
              parts = key.sub(rgx, "").split("__")
              # Remove empty start if needed
              if parts[0].to_s.empty?
                parts.shift
              end

              # For each part
              parts.each_with_index do |part, index|
                # Final part should store the value in the hash
                if index == parts.length - 1
                  tmp[part] = ENV[key]
                else
                  # Otherwise, downcase the partname
                  part.downcase!
                  # Set it to an object if needed
                  if !tmp.has_key? part
                    tmp[part] = {}
                  end
                  # Assign tmp to the new hash
                  tmp = tmp[part]
                end
              end
            end
          end

          # If we have set keys in the result return it
          if result.keys.length > 0
            return result
          end
        end

        return value
      end
    end # module Config
  end # module WorldModule
end # module LapisLazuli
