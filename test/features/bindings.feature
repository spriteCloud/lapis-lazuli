@bindings @p @ignore_on_remote
Feature: binding
When I want to test the Lapis Lazuli library
I want to run a webserver with some test files
And test if I can parse bindings when starting the browsers

  @bindings_01
  Scenario: bindings_01 - Custom user-agent firefox
    Given I use browser bindings "1"
    And I navigate to URL "http://whatsmyua.com/"
    Then within 2 seconds I should see "CUSTOM-USER-AGENT"
    And I close the browser

  @bindings_02
  Scenario: bindings_02 - Custom user-agent chrome
    Given I use browser bindings "2"
    And I navigate to URL "http://whatsmyua.com/"
    Then within 2 seconds I should see "CUSTOM-CHROME-USER-AGENT"
    And I close the browser

    # Known issue with maximizing the window using the chrome option --start-maximized
  @bindings_03 @maximize_issue
  Scenario: bindings_03 - Custom user-agent chrome
    Given I use browser bindings "3"
    And I navigate to URL "http://whatsmyua.com/"
    Then the browser window size should be "full screen"
    And I close the browser

  @bindings_04
  Scenario: bindings_04 - Using a pre-defined device (iphone5)
    Given I restart the browser to device setting "iphone5"
    When I navigate to URL "http://whatsmyua.com"
    Then within 2 seconds I should see "CPU iPhone OS 5_0 like Mac OS X"
    And the browser window size should be "640x1136"
    And I close the browser

  @bindings_05
  Scenario: bindings_05 - Using a pre-defined device (desktop1080)
    Given I restart the browser to device setting "desktop1080"
    When I navigate to URL "http://whatsmyua.com"
    Then within 2 seconds I should see "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3" disappear
    And the browser window size should be "1920x1080"
    And I close the browser