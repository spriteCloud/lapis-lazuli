@account
Feature: User accounts
  This feature will make sure the user account functionality is working as expected
  By checking registration, login and logout functionality

  # This is a best practise example. Please note the following
  # By defining a register, log-in and log-out state, we can easily re-use all these preconditions
  # All the scenario's aren't completed, but it should be easy to implement it into your own project.

  @account01 @log_in
  Scenario: account01 - Logging in
    Given the user is logged out
    When "default-user" logs in
    Then the page should display as logged in state

  @account02 @log_out
  Scenario: account01 - Logging out
    Given "default-user" is logged in
    When the user clicks on the logout button
    Then the page should display as logged out state

  @account03 @registration
  Scenario: account03 - Registation
    Given the user is logged out
    When "random-user" registers for a new account
    Then the page should display as logged in state
