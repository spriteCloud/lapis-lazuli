@modules @p
Feature: Modules
  When I want to test the Lapis Lazuli library
  I want to ensure that including modules works as expected

  @modules_01
  Scenario: modules_01 - World module
    Given I include a world module
    Then I expect the world module's functions to be available

  @modules_02
  Scenario: modules_02 - Browser module
    Given I include a browser module
    Then I expect the browser module's functions to be available
