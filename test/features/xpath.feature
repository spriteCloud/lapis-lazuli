@xpath @p
Feature: XPath Helpers
When I want to test the Lapis Lazuli library
Then I expect the xpath helper functions to work

@xpath_01
Scenario Outline: xpath_01 - contains helper without sepearator
  Given I navigate to the xpath test page
  And I specify a needle "<needle>" and a node "<node>" to xp_contains
  Then I expect an xpath fragment "<fragment>"
  And I expect the fragment "<fragment>" to find <n> element(s).

  Examples:
    | node   | needle | fragment                                                     | n |
    | @class | foo    | contains(concat(' ', normalize-space(@class), ' '), ' foo ') | 4 |
    | text() | foo    | contains(concat(' ', normalize-space(text()), ' '), ' foo ') | 4 |

@xpath_02
Scenario Outline: xpath_02 - contains helper with sepearator
  Given I navigate to the xpath test page
  And I specify a needle "<needle>" and a node "<node>" and an empty separator to xp_contains
  Then I expect an xpath fragment "<fragment>"
  And I expect the fragment "<fragment>" to find <n> element(s).

  Examples:
    | node   | needle | fragment                                                 | n |
    | @class | foo    | contains(concat('', normalize-space(@class), ''), 'foo') | 5 |
    | text() | foo    | contains(concat('', normalize-space(text()), ''), 'foo') | 5 |

@xpath_03
Scenario Outline: xpath_03 - operators
  Given I navigate to the xpath test page
  And I search for elements where node "<node>" contains "<first>" and not "<second>"
  Then I expect to find <n> elements.

  Examples:
    | node   | first | second | n |
    | @class | foo   | bar    | 1 |
    | @class | bar   | foo    | 0 |
    | text() | foo   | bar    | 1 |
    | text() | bar   | foo    | 0 |
