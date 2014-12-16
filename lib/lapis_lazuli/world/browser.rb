#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/browser"

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
      pp "#{self}: #{@browser}"
      pp "open? #{@browser.is_open?}"
      return (not @browser.nil? and @browser.is_open?)
    end

    ##
    # Get the current main browser
    def browser(*args)
      if @browser.nil?
        # Add LL to the arguments for the browser
        browser_args = args.unshift(self)
        # Create a new browser object
        @browser = LapisLazuli::Browser.new(*browser_args)

        # Register a finalizer, so we can clean up the proxy again
        ObjectSpace.define_finalizer(self, Browser.destroy(self))
      end

      if not @browser.is_open?
        @browser.start
      end

      return @browser
    end

  private

    def self.destroy(world)
      Proc.new do
        # First close the browser
        if world.has_browser?
          world.browser.destroy(world)
        end
      end
    end


  end # module Browser
end # module WorldModule
end # module LapisLazuli
