#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/browser"
require "lapis_lazuli/runtime"

require "lapis_lazuli/world/config"
require "lapis_lazuli/world/logging"
require "lapis_lazuli/world/error"
require "lapis_lazuli/world/proxy"

module LapisLazuli
module WorldModule
  ##
  # Module managing a browser instance
  module Browser
    include LapisLazuli::WorldModule::Config
    include LapisLazuli::WorldModule::Logging
    include LapisLazuli::WorldModule::Error
    include LapisLazuli::WorldModule::Proxy

    ##
    # Checks if there is a browser started
    def has_browser?
      b = Runtime.instance.get :browser
      return (not b.nil? and b.is_open?)
    end

    ##
    # Get the current main browser
    def browser(*args)
      b = Runtime.instance.get :browser
      if b.nil?
        # Add LL to the arguments for the browser
        browser_args = args.unshift(self)
        # Create a new browser object
        b = LapisLazuli::Browser.new(*browser_args)
        # Make it a "singleton"
        Runtime.instance.set(self, :browser, b)
      end

      if not b.is_open?
        b.start
      end

      return b
    end

  end # module Browser
end # module WorldModule
end # module LapisLazuli
