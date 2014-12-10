#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
require "lapis_lazuli"

# A reference to our library
ll = LapisLazuli::LapisLazuli.instance

Before do |scenario|
  ll.before_scenario(scenario)
end

After do |scenario|
  ll.after_scenario(scenario)
end

# Can be used for debug purposes
AfterStep('@pause') do |scenario|
  print "Press Return to continue"
  STDIN.getc
end

AfterConfiguration do |config|
  ll.after_configuration(config)
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
