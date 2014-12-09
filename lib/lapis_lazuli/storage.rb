#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
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
