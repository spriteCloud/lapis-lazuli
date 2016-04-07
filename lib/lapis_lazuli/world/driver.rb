#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2016 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/driver"
require "lapis_lazuli/runtime"

require "lapis_lazuli/world/config"
require "lapis_lazuli/world/logging"
require "lapis_lazuli/world/error"
require "lapis_lazuli/world/proxy"

module LapisLazuli
module WorldModule
  ##
  # Module managing a driver instance
  module Driver
    include LapisLazuli::WorldModule::Config
    include LapisLazuli::WorldModule::Logging
    include LapisLazuli::WorldModule::Error
    include LapisLazuli::WorldModule::Proxy

    ##
    # Store extension modules for the driver
    module ClassMethods
      def driver_module(module_name)
        @extensions ||= []
        @extensions << module_name
      end

      def driver_modules
        @extensions
      end
    end
    extend ClassMethods

    ##
    # Checks if there is a driver started
    def has_driver?
      b = Runtime.instance.get :driver
      return (not b.nil? and b.is_open?)
    end

    ##
    # Get the current main driver
    def driver(*args)
      b = Runtime.instance.set_if(self, :driver) do
        # Add LL to the arguments for the driver
        LapisLazuli::Driver.set_world(self)

        # Create & return a new driver object
        drv = LapisLazuli::Driver.new(*args)

        # Determine driver capabilities
        caps = {}
        if drv.respond_to? :capabilites
          # Selenium first; the driver should just respond to "capabilities"
          caps = JSON.parse(drv.capabilities.to_json)
        elsif drv.respond_to? :driver and drv.driver.respond_to? :capabilities
          caps = JSON.parse(drv.driver.capabilities.to_json)
        else
          log.warning("Could not determine driver capabilities.")
        end

        # Store capabilites in metadata
        metadata = Runtime.instance.get(:metadata)
        if metadata
          metadata.set("driver", { capabilities: caps })
        end

        # Remote session ID
        sessionid = caps["webdriver.remote.sessionid"]
        if !sessionid.nil?
          metadata.set("sessionid", sessionid)
        end

        drv
      end

      if not b.is_open?
        b.start
      end

      return b
    end

  end # module Driver
end # module WorldModule
end # module LapisLazuli
