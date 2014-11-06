@example @p
Feature: Example Feature
  When I want to learn how to make test cases
  As a user of the test automation tool
  I want to run and adjust the tests below

  @example01
  Scenario: example01 - Google Search
    Given I navigate to Google in english
    And I search for "spriteCloud"
    Then I see "www.spriteCloud.com" on the page
