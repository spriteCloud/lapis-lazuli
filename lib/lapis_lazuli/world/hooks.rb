#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
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
      # Add hooks to one of the four queues :before, :after, :start or :end.
      HOOK_QUEUES = [
        :before,
        :after,
        :start,
      # :end # FIXME hard to implement. See issue #13
      ]

      def self.add_hook(queue, hook)
        if not HOOK_QUEUES.include?(queue)
          raise "Invalid hook queue #{queue}"
        end

        @@hooks ||= {}
        @@hooks[queue] ||= []
        @@hooks[queue] << hook
      end

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

        # Run 'start' queue once.
        @@started ||= false
        if not @@started
          @@started = true
          run_queue(:start, cuke_scenario)
        end

        # Run 'before' queue
        run_queue(:before, cuke_scenario)
      end

      ##
      # Hook invoked in AfterScenario
      def after_scenario_hook(cuke_scenario)
        # Run 'after' queue
        run_queue(:after, cuke_scenario)

        # Run 'end' queue
        # FIXME hard to implement; see issue #13

        # The current scenario has finished
        if respond_to? :scenario
          scenario.running = false
        end

        # Sleep if needed
        if respond_to? :config and has_env_or_config?("step_pause_time")
          sleep env_or_config("step_pause_time")
        end

        # Did we fail?
        if respond_to? :scenario and respond_to? :has_browser? and respond_to? :browser and respond_to? :config
          if has_browser? and (cuke_scenario.failed? or (scenario.check_browser_errors and browser.has_error?))
            # Take a screenshot if needed
            if has_env_or_config?('screenshot_on_failure')
              if env_or_config("screenshot_scheme") == "new"
                # Take screenshots on all active browsers
                LapisLazuli::Browser.browsers.each do |b|
                  fileloc = b.take_screenshot()
                end
              else
                browser.take_screenshot()
              end
            end
          end
        end

        # Close browser if needed
        if respond_to? :has_browser? and respond_to? :browser
          if has_browser?
            browser.close_after_scenario(cuke_scenario)
          end
        end
      end

      private
      def run_queue(queue, cuke_scenario)
        @@hooks ||= {}

        if @@hooks[queue].nil?
          return
        end

        @@hooks[queue].each do |hook|
          self.instance_exec(cuke_scenario, &hook)
        end
      end
    end # module Hooks
  end # module WorldModule
end # module LapisLazuli
