#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

Before do |scenario|
  if respond_to? :before_scenario_hook
    before_scenario_hook(scenario)
  end
end

After do |scenario|
  if respond_to? :after_scenario_hook
    after_scenario_hook(scenario)
  end
end

# Can be used for debug purposes
AfterStep('@pause') do |scenario|
  print "Press Return to continue"
  STDIN.getc
end
