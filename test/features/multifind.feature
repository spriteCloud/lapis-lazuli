@multifind @p
Feature: testing multifind

  @multifind01
  Scenario: multifind01 - multifind with 1 results
    Given I navigate to the find test page
    Then the user expects a result in a multi_find lookup

  @multifind02
  Scenario: multifind02 - multifind no results
    Given I navigate to the find test page
    Then the user expects an error in a multi_find lookup

  @multifind03
  Scenario: multifind03 - multifind with no results and no error
    Given I navigate to the find test page
    Then the user expects no error in a multi_find lookup

  @multifind04
  Scenario: multifind04 - multifind all with 8 results
    Given I navigate to the find test page
    Then the user expects 8 results in a multi_find_all lookup

  @multifind05
  Scenario: multifind05 - multifind all with 1 results
    Given I navigate to the find test page
    Then the user expects 1 results in a multi_find_all lookup

  @multifind06
  Scenario: multifind06 - multifind all with 5 results
    Given I navigate to the find test page
    Then the user expects 5 existing results in a multi_find_all lookup

  @multifind07
  Scenario: multifind07 - multifind all with no results
    Given I navigate to the find test page
    Then the user expects an error in a multi_find_all lookup

  @multifind08
  Scenario: multifind08 - multifind all with no results and no error
    Given I navigate to the find test page
    Then the user expects no error in a multi_find_all lookup

  @multifind09
  Scenario: multifind09 - multifind all natching all elements with no results
    Given I navigate to the find test page
    Then the user expects an error in a multi_find_all lookup matching all elements

  @multifind10
  Scenario:  multifind10 - multifind all natching all elements with no error
    Given I navigate to the find test page
    Then the user expects no error in a multi_find_all lookup matching all elements