@screenshot @p
Feature: Screenshot
When I want to test the Lapis Lazuli library
I want to run a webserver with some test files
And execute the each library function searches for elements.

  @screenshot_01
  Scenario: screenshot_01 - Successfull scenario with screenshots
    Given I navigate to the screenshot test page
    When I take a screenshot
    Then I take a screenshot

  @screenshot_02
  Scenario: screenshot_02 - Taking a screenshot on a failed scenario
    Given I navigate to the screenshot test page
    Then I fail this step

  @screenshot_03
  Scenario Outline: screenshot_03 - Successfull scenario outlines with screenshots
    Given I navigate to the screenshot test page
    When I take a screenshot
    Then I take a screenshot
    Examples:
      | fails         |
      | failing once  |
      | failing twice |

  @screenshot_04
  Scenario Outline: screenshot_04 - Failing in a scenario outline
    Given I navigate to the screenshot test page
    Then I fail this step
    Examples:
      | fails         |
      | failing once  |
      | failing twice |