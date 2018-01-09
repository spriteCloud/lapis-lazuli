#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
module LapisLazuli
  ##
  # Configuration options and their default values
  CONFIG_OPTIONS = {
    "close_browser_after" => ["end", "Close the browser after every scenario, feature, etc. Possible values are 'feature', 'scenario', 'end' and 'never'."],
    "error_strings" => [nil, "List of strings that indicate errors when detected on a web page."],
    "default_env" => [nil, "Indicates which environment specific configuration to load when no test environment is provided explicitly."],
    "test_env" => [nil, "Indicates which environment specific configuration to load in this test run."],
    "browser" => [nil, "Indicates the browser in which to run tests. Possible values are 'firefox', 'chrome', 'safari', 'ie', 'ios'."],
    "email_domain" => ["google.com", "The domain name used when generating email addresses. See the `placeholders` command for more information."],
    "screenshot_on_failure" => [true, "Toggle whether failed scenarios should result in a screenshot being taken automatically."],
    "screenshot_dir" => [".#{File::SEPARATOR}screenshots", "Location prefix for the screenshot path."],
    "screenshots_height" => [nil, "When 'full' the window will be resized to max height before taking a screenshot"],
    "screenshot_scheme" => ["old", "Naming scheme for screenshots. Possible values are 'old' and 'new'. This option will be deprecated in the near future, and only the new scheme will be supported."],
    "breakpoint_on_error" => [false, "If the error() function is used to create errors, should the debugger be started?"],
    "step_pause_time" => [0, "(Deprecated) Number of seconds to wait after each cucumber step is executed."],
    "log_dir" => [".#{File::SEPARATOR}logs", "Location for log files; they'll be named like the configuration file but with the '.log' extension."],
    "log_file" => [nil, "Location of log file; overrides 'log_dir'."],
    "log_level" => ['DEBUG', "Log level; see ruby Logger class for details."],
    "storage_dir" => [".#{File::SEPARATOR}storage", "Location prefix where to output test information file with the '.json' extension."]
  }
end # module LapisLazuli
