require "json"
require "singleton"
require "lapis_lazuli/logger"
require "lapis_lazuli/scenario"
require "lapis_lazuli/browser"

module LapisLazuli
  class LapisLazuli
    include Singleton
    @browser
    @config
    @env
    attr_reader :log, :scenario, :time
    attr_accessor :scenario, :time

    def initialize
      if ENV["TEST_ENV"]
        @env = ENV["TEST_ENV"]
      end

      @time = {
        :timestamp => Time.now.strftime('%y%m%d_%H%M%S'),
        :epoch => Time.now.to_i.to_s
      }
    end

    def init(config_name)
      # Load the configuration file
      self.load_config(config_name)

      if @config.nil?
        raise "Could not load a configuration"
      end

      # Start the logger
      #
      log_file = "log/#{File.basename(config_name, ".*")}.log"
      if self.has_env?("logfile")
        log_file = self.env("logfile")
        p "Has env logfile #{self.env("logfile")}"
      end
      p "Logfile #{log_file}"
      @log = TeeLogger.new(log_file)

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
      if @config.nil?
        begin
          ext = File.extname(filename)
          if ext == ".yml"
            @config = YAML.load_file(filename)
          elsif ext == ".json"
            json = File.read(filename)
            @config = JSON.parse(json)
          end
        rescue RuntimeError => err
          raise "Error loading file: #{filename} #{err}"
        end
      end

      if @env and not self.has_config?(@env)
        raise "Environment doesn't exist in config file"
      end

      if @env.nil? and self.has_config?("default_env")
        env = self.config("default_env")
        if self.has_config?(env)
          @env = env
        else
          raise "Default environment not set"
        end
      end
    end

    def has_config?(variable)
        begin
          value = self.config(variable)
          return (not value.nil?)
        rescue
          return false
        end
    end

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

    def has_env?(variable)
      return self.has_config?("#{@env}.#{variable}")
    end

    def env(variable=false, default=nil)
      if not variable
        return self.config(@env)
      end
      return self.config("#{@env}.#{variable}",default)
    end

    def browser
      if @browser.nil?
        @browser = Browser.new(self)
      end
      return @browser
    end

    def error(settings=nil)
      message = "An unknown error occurred"
      if not settings.nil?
        if settings.is_a? String
          message = settings
        elsif settings.has_key? :message
          message = settings[:message]
        elsif settings.has_key? :env
          exists = ""
          if not (settings.has_key?(:exists) or settings[:exists])
            exists = ' not'
          end
          message = "Environment setting '#{settings[:env]}'" +
                    exists + " found"
        elsif settings.has_key? :text
        end
      end
      raise message
    end

    def variable(string)
      string.gsub!("EPOCH_TIMESTAMP", @time[:epoch])
      string.gsub!("TIMESTAMP",@time[:timestamp])
    end
  end
end
