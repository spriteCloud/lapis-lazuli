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
    Then within 2 seconds I get an error waiting for "waiting" to disappear
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

  @timing_09
  Scenario Outline: Wait with context
    Given I navigate to the find test page
    When I wait for "<context>" and name it "test_element"
    Then I should wait for "<element>" using "test_element" as context
    And I should not wait for "<error_element>" using "test_element" as context

    Examples:
      | context | element | error_element |
      | deep3   | deep6   | deep1         |
      | deep2   | deep7   | deep1         |
      | deep6   | deep7   | header        |

  @timing_10
  Scenario Outline: WaitAllPresent with context
    Given I navigate to the find test page
    When I wait for "<context>" and name it "test_element"
    Then I should wait for "<element>" <number> times using "test_element" as context
    Examples:
      | context | element        | number |
      | deep3   | deep6          | 1      |
      | deep3   | count          | 4      |
      | deep3   | does_not_exist | 0      |

  @timing_11
  Scenario: timing_11 - Waiting for an element in another element you waited for
    Given I navigate to the timing test page
    When I wait for class "asdf-foo-bar" and name it "test_element"
    And I should wait for "inner-div" using "test_element" as context
    Then that element should not container text "fake"

  @timing_12
  Scenario: timing_12 - Not throwing an error when failing
    Given I navigate to the timing test page
    Then no error should be thrown when waiting for "not_exist"