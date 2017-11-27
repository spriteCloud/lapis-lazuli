@basic @all_env
Feature: Example Feature
When I want to learn how to make test cases
As a user of the test automation tool
I want to run and adjust the tests below

  @basic_01
  Scenario: example01 - Spritecloud search
    Given the user navigates to "blog"
    When the user searches for "lapis lazuli"
    Then text "Open Source" should display somewhere on the page

  @basic_02
  Scenario: example02 - Going to a search result
    Given the user navigates to "https://spritecloud.com/?s=lapis+lazuli"
    When the user clicks on link "/announcing-lapislazuli/"
    Then text "Let's talk about testing" should display somewhere on the page

  @basic_03
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

  ### LEARNING TO DEBUG ###
  # Scenario' or Feature's including the tag @dev will be ingored when running a regular profile. To run this do:
  # bundle exec cucumber -t @basic_04 -p debug
  # or, if you want to test it on a specific environment:
  # bundle exec cucumber -p production -p debug -t @basic_04
  # Good luck fixing the problems!
  @basic_04 @dev
  Scenario: example_04 - confirming there is a no results page
    Given the user navigates to "blog"
    When the user searches for "no_results_expected"
    Then the text "Nothing Found" should display on the blog page
