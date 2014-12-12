#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "faraday"

module LapisLazuli
  ##
  # Proxy class to map to sc-proxy
  class API
    attr_reader :conn
    def initialize()
    end

    def set_conn(url, options=nil, &block)
      @conn = Faraday.new(url, options, &block)
    end

    ##
    # Map any missing method to the conn object or Faraday
    def respond_to?(meth)
      return (!@conn.nil? and @conn.respond_to? meth)
    end

    def method_missing(meth, *args, &block)
      if !@conn.nil? and @conn.respond_to? meth
        return @conn.send(meth.to_s, *args, &block)
      end
      return Faraday.send(meth.to_s, *args, &block)
    end
  end # class API
end # module LapisLazuli
