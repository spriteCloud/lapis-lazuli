#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "faraday"
require "faraday_middleware"
require "multi_xml"

module LapisLazuli
  ##
  # Proxy class to map to sc-proxy
  class API
    # Link to main lapis_lazuli class
    @ll
    attr_reader :conn
    def initialize()
    end

    def set_conn(url, options=nil, &block)
      block = block_given? ? block : Proc.new do |conn|
        conn.response :xml,  :content_type => /\bxml$/
        conn.response :json, :content_type => /\bjson$/

        conn.adapter Faraday.default_adapter
      end
      @conn = Faraday.new(url, options, &block)
    end

    def ll
      if @ll.nil?
        @ll = World.instance
      end
      return @ll
    end
    ##
    # Map any missing method to the conn object or Faraday
    def method_missing(meth, *args, &block)
      if !@conn.nil? and @conn.respond_to? meth
        return @conn.send(meth.to_s, *args, &block)
      end
      begin
        return Faraday.send(meth.to_s, *args, &block)
      rescue
        self.ll.error("Browser Method Missing: #{meth}")
      end
    end
  end # class API
end # module LapisLazuli
