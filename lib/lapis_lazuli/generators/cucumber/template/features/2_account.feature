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
    When "test-user" logs in
    Then the page should display as logged in state

  @account_02 @log_out
  Scenario: account_02 - Logging out
    Given "test-user" is logged in
    When the user clicks on the logout button
    Then the page should display as logged out state

  @account_03
  Scenario: account_03 - Opening the registration form
    Given the user is logged out
    When the user clicks on the registration button
    Then the registration form should display

  @account_04
  Scenario: account_04 - Successful registration
    Given "default-user" has the registration form opened
    When the user completes registration
    Then the successful registration message should display

  @account_05
  Scenario: account_05 - Logging in a new registration
    Given "default-user" has registered a new account
    When the user logs in
    Then the page should display as logged in state