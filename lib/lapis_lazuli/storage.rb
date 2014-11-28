module LapisLazuli
  ##
  # Simple storage class
  class Storage
    @data
    def initialize
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
  end
end
