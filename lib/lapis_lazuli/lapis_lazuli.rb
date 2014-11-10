require "json"
require "singleton"
require "lapis_lazuli/logger"
require "lapis_lazuli/scenario"
require "lapis_lazuli/browser"

module LapisLazuli
  ##
  # Lapis Lazuli class that handles everything
  #
  # Singleton class so that you can get the configuration everywhere
  #
  # Example
  # ll = LapisLazuli::LapisLazuli.instance
  # ll.config("default_env")
  # ll.browser.goto("http://www.spritecloud.com")
  # ll.log.debug("LL example")
  # ll.scenario.name
  class LapisLazuli
    include Singleton
    # The browser
    @browser
    # Loaded configuration file
    @config
    # Current environment
    @env
    attr_reader :log, :scenario, :time
    attr_accessor :scenario, :time

    ##
    # Initialize of the singleton. Only called once
    # Sets the env to TEST_ENV and populates time with starttime
    def initialize
      if ENV["TEST_ENV"]
        @env = ENV["TEST_ENV"]
      end

      @time = {
        :timestamp => Time.now.strftime('%y%m%d_%H%M%S'),
        :epoch => Time.now.to_i.to_s
      }

    end

    ##
    # Loads a configuration file, creates a logger and scenario information
    def init(config_name)
      # Load the configuration file
      self.load_config(config_name)

      # We should have a config
      if @config.nil?
        raise "Could not load a configuration"
      end

      # Start the logger with the config filename
      log_file = "log/#{File.basename(config_name, ".*")}.log"
      # Or a filename from the environment
      if self.has_env?("logfile")
        log_file = self.env("logfile")
      end
      @log = TeeLogger.new(log_file)

      # Current scenario information
      @scenario = Scenario.new
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

      # Do we have an environment
      if not @env.nil?
        # Add it to the suffixes
        suffixes.unshift(@env)
      end

      # For each suffix
      suffixes.each do |suffix|
        begin
          # Try to load a config file
          self.load_config_from_file("#{dir}/#{basename}-#{suffix}#{ext}")
        rescue
          # Do nothing, load the next file
        end

        # Stop if we have a config
        if @config
          break
        end
      end

      # Try to load the original filename if we don't have a config
      if @config.nil?
        load_config_from_file(config_name)
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
      if @env and not self.has_config?(@env)
        raise "Environment doesn't exist in config file"
      end

      # If we don't have one then load the default
      if @env.nil? and self.has_config?("default_env")
        env = self.config("default_env")
        if self.has_config?(env)
          @env = env
        else
          # We need a config...
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
      result = @config
      if not variable
        return result
      end
      variable.split(".").each do |part|
        if result.nil?
          raise "Incorrect configuration variable"
        end
        result = result[part]
      end
      return result || default
    end

    ##
    # Does the environment have a certain config variable
    def has_env?(variable)
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
    # Get the current main browser
    def browser
      if @browser.nil?
        @browser = Browser.new(self)
      end
      return @browser
    end

    ##
    # Throw an error based on some settings
    #
    # Examples:
    # ll.error("Simple message") => "Simple message"
    # ll.error(:message => "Simple message") => "Simple message"
    # ll.error(:env => "test") => "Environment setting 'test' not found"
    # ll.error(:env => "test", :exists: true) => "Environment setting 'test' found"
    def error(settings=nil)
      # Default message
      message = "An unknown error occurred"
      # Do we have settings
      if not settings.nil?
        # Simple string input
        if settings.is_a? String
          message = settings
        elsif settings.has_key? :message
          message = settings[:message]
        # Environment errors
        elsif settings.has_key? :env
          # Does the value exist or not?
          exists = ""
          if not (settings.has_key?(:exists) or settings[:exists])
            exists = ' not'
          end
          message = "Environment setting '#{settings[:env]}'" +
                    exists + " found"
        end
      end
      # Write the error to the log
      self.log.error(message)

      if ENV['BREAKPOINT_ON_FAILURE'] || self.config("breakpoint_on_failure")
        require "byebug"
        byebug
      end
      # Raise the message
      raise message
    end

    ##
    # Update the variable with timestamps
    # TODO: Add random data like random-email or random-name
    def variable(string)
      string.gsub!("EPOCH_TIMESTAMP", @time[:epoch])
      string.gsub!("TIMESTAMP",@time[:timestamp])
    end
  end
end
