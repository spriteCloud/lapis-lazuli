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
    #And I close the browser

  @bindings_02
  Scenario: Custom user-agent chrome
    Given I use browser bindings "2"
    And I navigate to URL "http://whatsmyua.com/"
    Then within 2 seconds I should see "CUSTOM-CHROME-USER-AGENT"
    #And I close the browser

  @bindings_03
  Scenario: Custom user-agent chrome
    Given I use browser bindings "3"
    And I navigate to URL "http://whatsmyua.com/"
    Then the browser window size should be "full screen"
    #And I close the browser

  @bindings_04
  Scenario: Using a pre-defined device
    Given I restart the browser to device setting "iphone5"
    When I navigate to URL "http://whatsmyua.com"
    Then within 2 seconds I should see "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
    And the browser window size should be "640x1136"

  @bindings_05
  Scenario: Checkin the browser dimensions
    Given I restart the browser to device setting "iphone5"
    When I navigate to URL "http://whatsmyua.com"
    Then within 2 seconds I should see "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"