@timing @p
Feature: Timing
  When I want to test the Lapis Lazuli library
  I want to run a webserver with some test files
  And execute the each library function that handles timing.

  @timing_01
  Scenario: timing_01 - Wait Until
    Given I navigate to the timing test page
    Then within 3 seconds I should see "content"

  @timing_02
  Scenario: timing_02 - Wait While
    Given I navigate to the timing test page
    Then within 3 seconds I should see "waiting" disappear

  @timing_03
  Scenario: timing_02 - Wait Until Error
    Given I navigate to the timing test page
    Then within 2 seconds I get an error waiting for "content"
    And a screenshot should have been created

  @timing_04
  Scenario: timing_02 - Wait While Error
    Given I navigate to the timing test page
    Then within 2 seconds I get an error waiting for "waiting" disappear
    And a screenshot should have been created
