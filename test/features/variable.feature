@variable @p
Feature: Variables
  When I want to test the Lapis Lazuli library
  I want to run a webserver with some test files
  And execute each library function that handles variables.

  @variable_01
  Scenario: variable_01 - Email replacement
    Given I generate and store an email
    Then I can retrieve the email
    And I expect the email to contain the domain name I specified.
