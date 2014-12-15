@click @p
Feature: clicks
  When I want to test the Lapis Lazuli library
  I want to run a webserver with some test files
  And execute the each library function that handles clicks.

  @click_01
  Scenario: click_01 - use onClick event
    Given I navigate to the button test page
    And I click the last button
    Then I should be able to click the first button by event

  @click_02
  Scenario: click_02 - use JavaScript
    Given I navigate to the button test page
    And I click the last button
    Then I should be able to click the first button by using JavaScript

  @click_03
  Scenario Outline: click_03 - use click types
    Given I navigate to the button test page
    And I click the last button
    Then I should be able to click the first button by click type <type>

    Examples:
      | type   |
      | method |
      | event  |
      | js     |

  @click_04
  Scenario: click_04 - use force click
    Given I navigate to the button test page
    And I click the last button
    Then I should be able to click the first button by force click
