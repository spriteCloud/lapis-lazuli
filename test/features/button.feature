@button @p
Feature: Buttons
  When I want to test the Lapis Lazuli library
  I want to run a webserver with some test files
  And execute the each library function that handles buttons.

  @button_01
  Scenario: button_01 - Find First
    Given I navigate to the button test page
    Then the first button should be the first element on the page
    And the 1st button should be the first element on the page
    And the first button should not be the last element on the page

  @button_02
  Scenario: button_02 - Find based on index
    Given I navigate to the button test page
    Then the 3rd button should be the 3rd element on the page
    And the 3rd button should not be the 2nd element on the page
    And the 3rd button should not be the last element on the page
    And the 3rd button should not be the first element on the page

  @button_03
  Scenario: button_03 - Hidden elements
    Given I navigate to the button test page
    Then the 4th button should not be present
    And the 5th button should be present

  @button_04
  Scenario: button_04 - Clicking First
    Given I navigate to the button test page
    And I click the first button
    Then within 1 seconds I should see "first clicked"

  @button_05
  Scenario: button_05 - Clicking Last
    Given I navigate to the button test page
    And I click the last button
    Then within 1 seconds I should see "last clicked"
