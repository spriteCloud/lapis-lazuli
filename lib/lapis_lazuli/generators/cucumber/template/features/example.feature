@example @p
Feature: Example Feature
When I want to learn how to make test cases
As a user of the test automation tool
I want to run and adjust the tests below

  @example01
  Scenario: example01 - Spritecloud search
    Given the user navigates to "blog"
    When the user searches for "lapis lazuli"
    Then text "Open Source" should display

  @example02
  Scenario: example02 - Going to a search result
    Given the user has searched for "lapis lazuli" on "blog"
    When the user clicks on link "/announcing-lapislazuli/"
    Then text "Let's talk about testing" should display

  @example03
  Scenario Outline: example03 - checking multiple pages for the logo
    Given the user navigates to "<page>"
    When the user clicks on the spritecloud logo
    Then the user should be on page "home"
    Scenarios:
      | page               |
      | blog               |
      | home               |
      | about-us           |
      | testing            |
      | functional-testing |
