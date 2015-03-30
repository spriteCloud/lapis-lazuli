@error @p
Feature: Error
  When I want to test the Lapis Lazuli library
  I want to run a webserver with some test files
  And execute the each library function that handles errors.

  @error_01 @needsproxy
  Scenario: error_01 - Has JS error
    Given I navigate to the javascript error test page
    Then I expect javascript errors

  @error_02 @needsproxy
  Scenario: error_02 - Status Code 404
    Given I navigate to the 404 test page
    Then I expect a 404 status code

  @error_04 @needsproxy
  Scenario: error_03 - Status Code 200
    Given I navigate to the text fields test page
    Then I expect a 200 status code

  @error_04
  Scenario: error_04 - HTML Error
    Given I navigate to the error html test page
    Then I expect 1 HTML error

  @error_05
  Scenario: error_05 - HTML Error
    Given I navigate to the text fields test page
    Then I expect no HTML error
