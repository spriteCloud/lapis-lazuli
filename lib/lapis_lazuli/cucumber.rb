require "lapis_lazuli"

# A reference to our library
ll = LapisLazuli::LapisLazuli.instance

Before do |scenario|
  # Update the scenario informaton
  ll.scenario.running = true
  ll.scenario.update(scenario)
  # Show the name
  ll.log.info("Starting Scenario: #{ll.scenario.id}")
end

After do |scenario|
  # The current scenario has finished
  ll.scenario.running = false

  # Sleep if needed
  if ll.has_env?("step_pause_time")
    sleep ll.env("step_pause_time", 0)
  end

  # Did we fail?
  if (scenario.failed? or (ll.scenario.check_browser_errors and ll.browser.has_error?))
    # Take a screenshot if needed
    if ll.has_config?('make_screenshot_on_failed_scenario')
      ll.browser.take_screenshot()
    end
  end
  # Close browser if needed
  ll.browser.close_after_scenario(scenario)
end

# Can be used for debug purposes
AfterStep('@pause') do |scenario|
  print "Press Return to continue"
  STDIN.getc
end

# Closing the browser after the test, no reason to leave them lying around
at_exit do
  begin
    if ll.has_browser?
      ll.browser.close
    end
  rescue
    # Nope...
    ll.log.debug("Failed to close the browser, probably chrome")
  end
end
