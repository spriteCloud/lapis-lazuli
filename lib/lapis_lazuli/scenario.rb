module LapisLazuli
  class Scenario
    @data
    attr_reader :name
    attr_reader :time
    attr_accessor :running

    def update(scenario)
      @data = scenario
      @name = scenario.name.gsub(/^.*(\\|\/)/, '').gsub(/[^\w\.\-]/, '_').squeeze('_')
      @time = {
        :timestamp => Time.now.strftime('%y%m%d_%H%M%S'),
        :epoch => Time.now.to_i.to_s
      }
    end
  end
end
