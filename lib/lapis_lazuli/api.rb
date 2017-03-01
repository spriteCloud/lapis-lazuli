#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "faraday"
require "faraday_middleware"
require "faraday_json"
require "multi_xml"

module LapisLazuli
  ##
  # Proxy class to map to sc-proxy
  class API
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

    ##
    # Map any missing method to the conn object or Faraday
    def respond_to?(meth)
      if !@conn.nil? and @conn.respond_to? meth
        return true
      end
      return super
    end

    def method_missing(meth, *args, &block)
      if !@conn.nil? and @conn.respond_to? meth
        return @conn.send(meth.to_s, *args, &block)
      end

      begin
        return Faraday.send(meth.to_s, *args, &block)
      rescue NoMethodError
        return super
      end
    end
  end # class API
end # module LapisLazuli
