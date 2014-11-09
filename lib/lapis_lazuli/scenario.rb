module LapisLazuli
  ##
  # Stores the Cucumber scenario
  # Includes timing, running state and a name
  class Scenario
    @data
    attr_reader :name
    attr_reader :time
    attr_accessor :running

    ##
    # Update the scenario with a new one
    def update(scenario)
      # The original scenario from cucumber
      @data = scenario
      # A name without special characters
      @name = scenario.name.gsub(/^.*(\\|\/)/, '').gsub(/[^\w\.\-]/, '_').squeeze('_')
      # The current time
      @time = {
        :timestamp => Time.now.strftime('%y%m%d_%H%M%S'),
        :epoch => Time.now.to_i.to_s
      }
    end
  end
end
