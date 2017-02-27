#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'socket'
require 'timeout'
require "lapis_lazuli/api"

module LapisLazuli
  ##
  # Proxy class to map to sc-proxy
  class Proxy
    attr_reader :is_scproxy, :api, :ip, :scproxy_port, :port

    ##
    # Create a new LL Proxy
    # What is the ip/port of the master?
    def initialize(ip, port, scproxy=true)
      # Save the information
      @ip = ip
      @is_scproxy = scproxy
      if scproxy
        @scproxy_port = port
      else
        @port = port
      end
      # We should have a master
      if !is_port_open?(ip, port)
        raise "Proxy not online"
      end
      if @is_scproxy
        # Create an API connection to the master
        @api = API.new()
      end
    end

    def has_session?()
      return !@port.nil? && is_port_open?(@ip, @port);
    end

    ##
    # Creates a new session with the proxy
    def create()
      # Do we already have a connection?
      if @is_scproxy and self.has_session?
        # Close it before starting a new one
        self.close()
      end
      # Create a new
      if @is_scproxy and @api
        # Let the master create a new proxy
        response = self.proxy_new :master => true
        # Did we get on?
        if response["status"] == true
          @port = response["result"]["port"]
        else
          # Show the error
          raise response["message"]
        end
      end

      if @port.nil?
        raise "Coult not create a new proxy"
      end

      return @port
    end

    ##
    # Close the session with the proxy
    def close()
      # If we don't have one we don't do anything
      return if !@is_scproxy or !self.has_session?

      # Send the call to the master
      response = self.proxy_close :port => @port, :master => true

      # Did we close it?
      if response["status"] == true
        # Clear our session
        @port = nil
      else
        # Show an error
        raise response["message"]
      end
    end

    ##
    # Check if a TCP port is open on a host
    def is_port_open?(ip, port)
      begin
        # Timeout is important
        Timeout::timeout(1) do
          begin
            # Create the socket and close it
            s = TCPSocket.new(ip, port)
            s.close
            return true
          # If it fails the port is closed
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          end
        end
      rescue Timeout::Error
      end

      # Sorry port is closed
      return false
    end

    ##
    # Map any missing method to the API object
    #
    # Example
    # proxy.har_get
    # proxy.proxy_close :port => 10002
    def method_missing(meth, *args, &block)
      # Only for spritecloud proxies
      if !@is_scproxy
        raise "Incorrect method: #{meth}"
      end

      # We should have no arguments or a Hash
      if args.length > 1 or (args.length == 1 and not args[0].is_a? Hash)
        raise "Incorrect arguments: #{args}"
      end
      settings = args[0] || {}

      # A custom block or arguments?
      block = block_given? ? block : Proc.new do |req|
        if args.length == 1
          settings.each do |key,value|
            req.params[key.to_s] = value.to_s
          end
        end
      end

      # Pick the master proxy or the proxy for this session
      @api.set_conn("http://#{@ip}:#{(settings.has_key? :master) ? @scproxy_port : @port}/")

      # Call the API
      response = @api.get("/#{meth.to_s.gsub("_","/")}", nil, &block)
      # Only return the body if we could parse the JSOn
      if response.body.is_a? Hash
        return response.body
      else
        # Got a serious issue here, label as code 500
        return {
          "code" => 500,
          "status" => false,
          "message" => "Incorrect response from proxy",
          "result" => response
        }
      end
    end

    ##
    # During the end of the test run all data should be added to the storage
    def destroy(world)
      begin
        # Is it a spriteCloud proxy?
        if @is_scproxy
          # Request HAR data
          response = self.har_get
          if response["status"] == true
            # Add it to the storage
            world.storage.set("har", response["result"])
          end
        end
        self.close
      rescue StandardError => err
        world.log.debug("Failed to close the proxy: #{err}")
      end
    end
  end
end
