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
  Scenario: timing_03 - Wait Until Error
    Given I navigate to the timing test page
    Then within 2 seconds I get an error waiting for "content"
    And a screenshot should have been created

  @timing_04
  Scenario: timing_04 - Wait While Error
    Given I navigate to the timing test page
    Then within 2 seconds I get an error waiting for "waiting" disappear
    And a screenshot should have been created

  @timing_05
  Scenario: timing_05 - Wait until multiple
    Given I navigate to the timing test page
    Then within 3 seconds I should see "content" and "foo"

  @timing_06
  Scenario: timing_06 - Wait until multiple (defaults)
    Given I navigate to the timing test page
    Then within 10 seconds I should see either added element

  @timing_07
  Scenario: timing_07 - Wait until multiple with text/html matching
    Given I navigate to the timing test page
    Then within 3 seconds I should see added elements with matching

  @timing_08 @timing_errors @issue_9
  Scenario: timing_08 - Expect wait to throw
    Given I navigate to the timing test page
    Then within 3 seconds I should not see nonexistent elements
