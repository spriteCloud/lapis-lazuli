module LapisLazuli
  class Scenario
    @data
    attr_reader :name
    attr_reader :timecode
    attr_accessor :running

    def update(scenario)
      @data = scenario
      @name = scenario.name.gsub(/^.*(\\|\/)/, '').gsub(/[^\w\.\-]/, '_').squeeze('_')
      @timecode = "#{Time.now.strftime("%y%m%d_%H%M%S")}_#{@name}"
    end
  end
end
