@bindings @p
Feature: binding
When I want to test the Lapis Lazuli library
I want to run a webserver with some test files
And test if I can parse bindings when starting the browsers

  @bindings_01
  Scenario: Custom user-agent firefox
    Given I use browser bindings "1"
    And I navigate to URL "http://whatsmyua.com/"
    Then within 2 seconds I should see "CUSTOM-USER-AGENT"

  @bindings_02
  Scenario: Custom user-agent chrome
    Given I use browser bindings "2"
    And I navigate to URL "http://whatsmyua.com/"
    Then within 2 seconds I should see "CUSTOM-CHROME-USER-AGENT"

    # Known issue with maximizing the window using the chrome option --start-maximized
  @bindings_03 @maximize_issue
  Scenario: Custom user-agent chrome
    Given I use browser bindings "3"
    And I navigate to URL "http://whatsmyua.com/"
    Then the browser window size should be "full screen"

  @bindings_04
  Scenario: Using a pre-defined device (iphone5)
    Given I restart the browser to device setting "iphone5"
    When I navigate to URL "http://whatsmyua.com"
    Then within 2 seconds I should see "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
    And the browser window size should be "640x1136"

  @bindings_05
  Scenario: Using a pre-defined device (desktop1080)
    Given I restart the browser to device setting "desktop1080"
    When I navigate to URL "http://whatsmyua.com"
    Then within 2 seconds I should see "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3" disappear
    And the browser window size should be "1920x1080"