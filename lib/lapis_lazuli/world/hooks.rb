#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
module WorldModule
  ##
  # Module with cucumber hooks
  #
  # The module is special in that it does not include other modules. Instead it
  # always tests whether World responds to a function before calling it.
  module Hooks
    ##
    # Hook invoked in BeforeScenario
    def before_scenario_hook(cuke_scenario)
      # Update the scenario informaton
      if respond_to? :scenario
        scenario.running = true
        scenario.update(cuke_scenario)
      end

      # Show the name
      if respond_to? :log
        log.info("Starting Scenario: #{scenario.id}")
      end
    end

    ##
    # Hook invoked in AfterScenario
    def after_scenario_hook(cuke_scenario)
      # The current scenario has finished
      if respond_to? :scenario
        scenario.running = false
      end

      # Sleep if needed
      if respond_to? :config and has_env_or_config?("step_pause_time")
        sleep env_or_config("step_pause_time")
      end

      # Did we fail?
      if respond_to? :scenario and respond_to? :browser and respond_to? :config
        if (cuke_scenario.failed? or (scenario.check_browser_errors and browser.has_error?))
          # Take a screenshot if needed
          if has_env_or_config?('screenshot_on_failure')
            fileloc = browser.take_screenshot()
          end
        end
      end

      # Close browser if needed
      if respond_to? :browser
        browser.close_after_scenario(cuke_scenario)
      end
    end
  end # module Hooks
end # module WorldModule
end # module LapisLazuli
