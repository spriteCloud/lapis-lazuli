@text_field @p
Feature: Text Fields
  When I want to test the Lapis Lazuli library
  I want to run a webserver with some test files
  And execute the each library function that handles text fields.

  @text_field_01
  Scenario: text_field_01 - Find First
    Given I navigate to the text fields test page
    Then the first text field should be the first element on the page
    And the 1st text field should be the first element on the page
    And the first text field should not be the last element on the page

  @text_field_02
  Scenario: text_field_02 - Find Last
    Given I navigate to the text fields test page
    Then the last text field should not be the first element on the page
    And the last text field should be the last element on the page

  @text_field_03
  Scenario: text_field_03 - Find based on index
    Given I navigate to the text fields test page
    Then the 3rd text field should be the 3rd element on the page
    And the 3rd text field should not be the 2nd element on the page
    And the 3rd text field should not be the last element on the page
    And the 3rd text field should not be the first element on the page

  @text_field_04
  Scenario: text_field_04 - Hidden elements
    Given I navigate to the text fields test page
    Then the 4th text field should not be present
    And the 5th text field should be present
