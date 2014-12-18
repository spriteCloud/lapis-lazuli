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
    # Store extension modules for the browser
    module ClassMethods
      def browser_module(module_name)
        @extensions ||= []
        @extensions << module_name
      end

      def browser_modules
        @extensions
      end
    end
    extend ClassMethods

    ##
    # Checks if there is a browser started
    def has_browser?
      b = Runtime.instance.get :browser
      return (not b.nil? and b.is_open?)
    end

    ##
    # Get the current main browser
    def browser(*args)
      b = Runtime.instance.set_if(self, :browser) do
        # Add LL to the arguments for the browser
        browser_args = args.unshift(self)
        # Create a new browser object
        inst = LapisLazuli::Browser.new(*browser_args)
        # Extend the instance
        Browser.browser_modules.each do |ext|
          inst.extend(ext)
        end
        # Return the instance
        inst
      end

      if not b.is_open?
        b.start
      end

      return b
    end

  end # module Browser
end # module WorldModule
end # module LapisLazuli
