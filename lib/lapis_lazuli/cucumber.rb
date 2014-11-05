require "lapis_lazuli"
require "pp"

ll = LapisLazuli::LapisLazuli.instance

Before do |scenario|
  ll.scenario.running = true
  ll.scenario.update(scenario)
  ll.log.info("Starting Scenario: #{ll.scenario.name}")
end

After do |scenario|
  ll.scenario.running = false

  if ll.has_env?("step_pause_time")
    sleep ll.env("step_pause_time", 0)
  end

  if scenario.failed? and ll.has_config?('make_screenshot_on_failed_scenario')
    ll.browser.take_screenshot()
  end

  if scenario.failed? or ll.browser.has_error?
    raise "Scenario failed: #{ll.browser.url}"
  end
end

# Can be used for debug purposes
AfterStep('@pause') do
  print "Press Return to continue"
  STDIN.getc
end

# Closing the browser after the test, no reason to leave them lying around
at_exit do
  ll.browser.close
end
