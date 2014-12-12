#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
  ##
  # Module with cucumber hooks
  module Hooks
    ##
    # Hook invoked in AfterConfiguration
    def after_configuration_hook(config)
      config.options[:formats] << ["LapisLazuli::Formatter", STDERR]
    end

    ##
    # Hook invoked in BeforeScenario
    def before_scenario_hook(scenario)
      # Update the scenario informaton
      self.scenario.running = true
      self.scenario.update(scenario)
      # Show the name
      self.log.info("Starting Scenario: #{self.scenario.id}")
    end

    ##
    # Hook invoked in AfterScenario
    def after_scenario_hook(scenario)
      # The current scenario has finished
      self.scenario.running = false

      # Sleep if needed
      if self.has_env_or_config?("step_pause_time")
        sleep self.env_or_config("step_pause_time")
      end

      # Did we fail?
      if (scenario.failed? or (self.scenario.check_browser_errors and self.browser.has_error?))
        # Take a screenshot if needed
        if self.has_env_or_config?('screenshot_on_failure')
          fileloc = self.browser.take_screenshot()
          embed(fileloc, "image/png", "SCREENSHOT")
        end
      end
      # Close browser if needed
      self.browser.close_after_scenario(scenario)
    end
  end # module Hooks
end # module LapisLazuli
