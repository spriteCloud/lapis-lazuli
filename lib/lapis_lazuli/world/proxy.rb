#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/proxy"

require "lapis_lazuli/world/config"
require "lapis_lazuli/world/logging"

module LapisLazuli
module WorldModule
  ##
  # Module managing a proxy instance
  module Proxy
    include LapisLazuli::WorldModule::Config
    include LapisLazuli::WorldModule::Logging

    ##
    # Checks if there is a proxy started
    def has_proxy?
      return !@proxy.nil?
    end

    ##
    # Get the current proxy
    def proxy
      if not @proxy.nil?
        return @proxy
      end

      # Check if we can start a proxy
      begin
        # Default proxy settings
        proxy_ip = "localhost"
        proxy_port = 10000
        proxy_master = true

        # Do we have a config?
        if has_env_or_config?("proxy.ip") and has_env_or_config?("proxy.port")
          proxy_ip = env_or_config("proxy.ip")
          proxy_port = env_or_config("proxy.port")
          proxy_master = env_or_config("proxy.spritecloud", true)
        end

        # Try to start the proxy
        proxy = LapisLazuli::Proxy.new(proxy_ip, proxy_port, proxy_master)

        # Register a finalizer, so we can clean up the proxy again
        ObjectSpace.define_finalizer(self, self.class.destroy(self))

        log.debug("Found proxy: #{proxy_ip}:#{proxy_port}, spritecloud: #{proxy_master}")
        @proxy = proxy
      rescue StandardError => err
        log.debug("No proxy available: #{err}")
      end

      return @proxy
    end


  private

    def self.destroy(world)
      Proc.new do
        # Then the proxy
        if world.has_proxy?
          world.proxy.destroy(world)
        end
      end
    end


  end # module Proxy
end # module WorldModule
end # module LapisLazuli
