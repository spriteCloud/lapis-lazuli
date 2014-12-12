require 'socket'
require 'timeout'
require "lapis_lazuli/api"

module LapisLazuli
  ##
  # Proxy class to map to sc-proxy
  class Proxy
    attr_reader :has_master, :api, :ip, :master_port, :port

    ##
    # Create a new LL Proxy
    # What is the ip/port of the master?
    def initialize(ip, port, master=true)
      # Save the information
      @ip = ip
      @has_master = master
      if master
        @master_port = port
      else
        @port = port
      end
      # We should have a master
      if !is_port_open?(ip, port)
        raise "Proxy not online"
      end
      # Create an API connection to the master
      @api = API.new()
      @api.set_conn("http://#{@ip}:#{@master_port}/") do |conn|
        conn.response :xml,  :content_type => /\bxml$/
        conn.response :json, :content_type => /\bjson$/

        conn.adapter Faraday.default_adapter
      end
    end

    def has_session?()
      if !@has_master and !port.nil?
        return true
      end
      return !@port.nil? && is_port_open?(@ip, @port);
    end

    ##
    # Creates a new session with the proxy
    def create()
      # Do we already have a connection?
      if @has_master and self.has_session?
        # Close it before starting a new one
        self.close()
      end

      # Let the master create a new proxy
      response = @api.get("/proxy/new")
      # Did we get on?
      if response.body["status"] == true
        @port = response.body["result"]["port"]
      else
        # Show the error
        raise response.body["message"]
      end

      return @port
    end

    ##
    # Close the session with the proxy
    def close()
      # If we don't have one we don't do anything
      return if !@has_masster or !self.has_session?

      # Send the call to the master
      response = @api.get("/proxy/close") do |req|
        # Which port do we want to close?
        req.params["port"] = @port
      end

      # Did we close it?
      if response.body["status"] == true
        # Clear our session
        @port = nil
      else
        # Show an error
        raise response.body["message"]
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
  end
end
