#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
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
      proxy = Runtime.instance.get :proxy
      return !proxy.nil?
    end

    ##
    # Get the current proxy
    def proxy
      return Runtime.instance.set_if(self, :proxy) do
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

          log.debug("Found proxy: #{proxy_ip}:#{proxy_port}, spritecloud: #{proxy_master}")
        rescue StandardError => err
          log.debug("No proxy available: #{err}")
        end
      end
    end
  end # module Proxy
end # module WorldModule
end # module LapisLazuli
