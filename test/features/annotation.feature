@annotation @p
Feature: annotiations
  When I want to test the Lapis Lazuli library
  I want to run a webserver with some test files
  And execute the each library function that handles annotations.

  @annotation_01
  Scenario Outline: annotation_01 - scenario outline
    Given I annotate a step with <data1>
    And I annotate a step with <data2>
    Then the report should include <data1> and <data2> in the correct place

    Examples:
      | data1 | data2 |
      | foo   | bar   |
      | foo   |       |
      |       | bar   |

  @annotation_02
  Scenario: annotation_01 - single scenario
    Given I annotate a step with baz
    And I annotate a step with quux
    Then the report should include baz and quux in the correct place
