#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/proxy"
require "lapis_lazuli/runtime"

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
      p = Runtime.instance.get :proxy
      return !p.nil?
    end

    ##
    # Get the current proxy
    def proxy
      p = Runtime.instance.get :proxy
      if not p.nil?
        return p
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
        p = LapisLazuli::Proxy.new(proxy_ip, proxy_port, proxy_master)

        # Make it a "singleton"
        Runtime.instance.set(self, :proxy, p)

        log.debug("Found proxy: #{proxy_ip}:#{proxy_port}, spritecloud: #{proxy_master}")
      rescue StandardError => err
        log.debug("No proxy available: #{err}")
      end

      return p
    end
  end # module Proxy
end # module WorldModule
end # module LapisLazuli
