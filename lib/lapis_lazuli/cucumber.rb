#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

Before do |scenario|
  before_scenario_hook(scenario)
end

After do |scenario|
  after_scenario_hook(scenario)
end

# Can be used for debug purposes
AfterStep('@pause') do |scenario|
  print "Press Return to continue"
  STDIN.getc
end

AfterConfiguration do |config|
  config.options[:formats] << ["LapisLazuli::Formatter", STDERR]
end
