@config @p
Feature: config
  When I want to test the Lapis Lazuli library
  I want to run a webserver with some test files
  And execute the each library function that handles configurations.

  @config_01
  Scenario: config_01 - Environment Hash
    Given I set environment variable "configtest__user" to "username"
    And I set environment variable "configtest__pass" to "password"
    Then the environment variable "configtest" has "user" set to "username"
    And the environment variable "configtest.user" is set to "username"
    And the environment variable "configtest" has "pass" set to "password"
    And the environment variable "close_browser_after" is set to "feature"
