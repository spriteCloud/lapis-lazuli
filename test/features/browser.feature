@browser @p @ignore_on_remote
Feature: Browsers
When I want to test the Lapis Lazuli library
And test if I can start a browser with options

@browser_01
Scenario: browser_01 - Firefox with proxy
  When I create a firefox browser named "test" with proxy to "localhost:8008"
  Then the firefox browser named "test" has a profile
  Then I close the browser named "test"
