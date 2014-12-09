@find @p
Feature: Find
When I want to test the Lapis Lazuli library
I want to run a webserver with some test files
And execute the each library function searches for elements.

@find_01
Scenario: Find by string
  Given I navigate to the find test page
  Then I expect the "header" to exist
  And I expect the "footer" to exist

@find_02
Scenario: Find by element
  Given I navigate to the find test page
  Then I expect a nav element to exist
  And I expect a div element to exist

@find_03
Scenario Outline: Find by attribute
  Given I navigate to the find test page
  Then I expect to find a <element> element with <attribute> "<text>"

  Examples:
  | element | attribute | text |
  | button | class | submit |
  | a | href | /full/link |
