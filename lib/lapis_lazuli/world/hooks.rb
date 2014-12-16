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
  module Hooks
    ##
    # Hook invoked in BeforeScenario
    def before_scenario_hook(cuke_scenario)
      # Update the scenario informaton
      scenario.running = true
      scenario.update(cuke_scenario)
      # Show the name
      log.info("Starting Scenario: #{scenario.id}")
    end

    ##
    # Hook invoked in AfterScenario
    def after_scenario_hook(cuke_scenario)
      # The current scenario has finished
      scenario.running = false

      # Sleep if needed
      if has_env_or_config?("step_pause_time")
        sleep env_or_config("step_pause_time")
      end

      # Did we fail?
      if (cuke_scenario.failed? or (scenario.check_browser_errors and browser.has_error?))
        # Take a screenshot if needed
        if has_env_or_config?('screenshot_on_failure')
          fileloc = browser.take_screenshot()
        end
      end
      # Close browser if needed
      browser.close_after_scenario(cuke_scenario)
    end
  end # module Hooks
end # module WorldModule
end # module LapisLazuli
