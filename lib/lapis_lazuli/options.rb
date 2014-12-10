#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
module LapisLazuli
  ##
  # Configuration options and their default values
  CONFIG_OPTIONS = {
    "close_browser_after" => ["feature", "Close the browser after every scenario, feature, etc. Possible values are 'feature', 'scenario' and 'never'."],
    "error_strings" => [nil, "List of strings that indicate errors when detected on a web page."],
    "default_env" => [nil, "Indicates which environment specific configuration to load when no test environment is provided explicitly."],
    "test_env" => [nil, "Indicates which environment specific configuration to load in this test run."],
    "browser" => ['firefox', "Indicates the browser in which to run tests. Possible values are 'firefox', 'chrome', 'safari', 'ie', 'ios'."],
    "email_domain" => ["google.com", "FIXME"],
    "screenshot_on_failure" => [true, "Toggle whether failed scenarios should result in a screenshot being taken automatically."],
    "screenshot_dir" => ["FIXME", "Location prefix for the screenshot path."],
    "screenshot_scheme" => ["old", "Naming scheme for screenshots. Possible values are 'old' and 'new'. This option will be deprecated in the near future."],
    "breakpoint_on_error" => [false, "If the error() function is used to create errors, should the debugger be started?"],
  }
end # module LapisLazuli
