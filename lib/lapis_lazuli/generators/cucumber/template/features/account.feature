@account @all_env
Feature: User accounts
  This feature will make sure the user account functionality is working as expected
  By checking registration, login and logout functionality

  # This is a best practise example. Please note the following
  # By defining a register, log-in and log-out state, we can easily re-use all these preconditions
  # All the scenario's aren't completed, but it should be easy to implement it into your own project.

  @account_01 @log_in #@pause # You can add @pause to have a break between every step.
  Scenario: account_01 - Logging in
    Given the user is logged out
    When "default-user" logs in
    Then the page should display as logged in state

  @account_02 @log_out
  Scenario: account_02 - Logging out
    Given "default-user" is logged in
    When the user clicks on the logout button
    Then the page should display as logged out state

  @account_03 @registration
  Scenario: account_03 - Registration
    Given the user is logged out
    When "random-user" registers for a new account
    Then the page should display as logged in state

    @account_04 @registration
      Scenario: account_04 -