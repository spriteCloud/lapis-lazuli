@find @p
Feature: Find
When I want to test the Lapis Lazuli library
I want to run a webserver with some test files
And execute the each library function searches for elements.

@find_01
Scenario: Find by string
  Given I navigate to the find test page
  Then I expect the "header" to exist
  And I expect the "footer" to exist

@find_02
Scenario: Find by element
  Given I navigate to the find test page
  Then I expect a nav element to exist
  And I expect a div element to exist

@find_03
Scenario Outline: Find by attribute
  Given I navigate to the find test page
  Then I expect to find a <element> element with <attribute> "<text>" using <settings> settings

  Examples:
  | element | attribute | text       | settings        |
  | button  | class     | submit     | method          |
  | a       | href      | /full/link | method          |
  | div     | text      | Second     | method          |
  | button  | class     | submit     | like with hash  |
  | a       | href      | /full/link | like with hash  |
  | div     | text      | Second     | like with hash  |
  | button  | class     | submit     | like with array |
  | a       | href      | /full/link | like with array |
  | div     | text      | Second     | like with array |
  | button  | class     | submit     | tag name        |
# :tag_name + :href not supported by watir
# | a       | href      | /full/link | tag name        |
  | div     | text      | Second     | tag name        |

@find_04
Scenario Outline: Find one of multiple
  Given I navigate to the find test page
  Then I expect to find a <element1> element or a <element2> element

  Examples:
  | element1 | element2 |
  | a | does_not_exist |
  | does_not_exist | a |

@find_05
Scenario Outline: Find with context
  Given I navigate to the find test page
  When I find "<context>" and name it "test_element"
  Then I should find "<element>" using "test_element" as context
  And I should not find "<error_element>" using "test_element" as context

  Examples:
  | context | element | error_element |
  | deep3 | deep6 | deep1 |
  | deep2 | deep7 | deep1 |
  | deep6 | deep7 | header |

@find_06
Scenario Outline: FindAllPresent with context
  Given I navigate to the find test page
  When I find "<context>" and name it "test_element"
  Then I should find "<element>" <number> times using "test_element" as context
  Examples:
  | context | element        | number |
  | deep3   | deep6          | 1      |
  | deep3   | count          | 4      |
  | deep3   | does_not_exist | 0      |

@find_07 @find_errors @issue_6
Scenario: Find in always returns an element, defaulting to the document root
  Given I navigate to the find test page
  Then I expect not to find "does_not_exist"

@find_08 @find_errors @issue_6
Scenario Outline: Find with tagname to hash options seems broken
  Given I navigate to the find test page
  Then I expect to use tagname to hash options to <mode> find element <element>

  Examples:
  | element        | mode |
  | deep3          |      |
  | does_not_exist | not  |

@find_09 @issue_8
Scenario: Find should throw, unless no :throw is specified
  Given I navigate to the find test page
  Then I expect not to find "does_not_exist" with no :throw option
