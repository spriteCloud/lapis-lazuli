require "securerandom"
require "lapis_lazuli/storage"

module LapisLazuli
  ##
  # Stores the Cucumber scenario
  # Includes timing, running state and a name
  class Scenario
    attr_reader :name, :time, :uuid, :data, :storage
    attr_accessor :running, :check_browser_errors

    def initialize
      @uuid = SecureRandom.hex
      @storage = Storage.new
      @running = false
      @name = "start_of_test_run"
      self.update_timestamp
    end
    ##
    # Update the scenario with a new one
    def update(scenario)
      @uuid = SecureRandom.hex
      # Reset the fail attribute
      @check_browser_errors = true
      # The original scenario from cucumber
      @data = scenario
      # A name without special characters
      @name = scenario.name.gsub(/^.*(\\|\/)/, '').gsub(/[^\w\.\-]/, '_').squeeze('_')
      self.update_timestamp
    end

    def update_timestamp
      now = Time.now
      # The current time
      @time = {
        :timestamp => now.strftime('%y%m%d_%H%M%S'),
        :epoch => now.to_i.to_s
      }
    end

  end
end
