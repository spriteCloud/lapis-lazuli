@jserror @p
Feature: Javascript Error
  When I want to test the Lapis Lazuli library
  I want to run a webserver with some test files
  And execute the each library function that handles Javascript errors.

  @jserror_01
  Scenario: jserror_01 - Has error
    Given I navigate to the javascript_error test page
    Then I expect javascript errors
