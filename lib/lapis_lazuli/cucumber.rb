require "lapis_lazuli"

# A reference to our library
ll = LapisLazuli::LapisLazuli.instance

Before do |scenario|
  # Update the scenario informaton
  ll.scenario.running = true
  ll.scenario.update(scenario)
  # Show the name
  ll.log.info("Starting Scenario: #{ll.scenario.name}")
end

After do |scenario|
  # The current scenario has finished
  ll.scenario.running = false

  # Sleep if needed
  if ll.has_env?("step_pause_time")
    sleep ll.env("step_pause_time", 0)
  end

  # Take a screenshot if needed
  if scenario.failed? and ll.has_config?('make_screenshot_on_failed_scenario')
    ll.browser.take_screenshot()
  end

  # Show the URL if we failed
  if scenario.failed? or ll.browser.has_error?
    raise "Scenario failed: #{ll.browser.url}"
  end
end

# Can be used for debug purposes
AfterStep('@pause') do |scenario|
  print "Press Return to continue"
  STDIN.getc
end

# Closing the browser after the test, no reason to leave them lying around
at_exit do
  ll.browser.close
end
