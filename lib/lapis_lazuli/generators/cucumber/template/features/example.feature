@example @p
Feature: Example Feature
When I want to learn how to make test cases
As a user of the test automation tool
I want to run and adjust the tests below

    @example01
    Scenario: example01 - Google Search
        Given the user navigates to Google in english
        When the user searches for "spriteCloud"
        Then text "www.spriteCloud.com" should display

    @example02
    Scenario: example02 - Going to a search result
        Given the user has searched for "spriteCloud" on Google in english
        When the user clicks on link "spritecloud.com"
        Then text "Test your software, not your reputation" should display