@todo @all_env
Feature: Todo list
  In this feature we will test the todo functionality
  We do this by adding, completing and deleting the todo lists'

  @todo_01
  Scenario: todo_01 - adding a todo item
    Given "test-user" is logged in
    When a todo item with text "Hello world" is added
    Then a todo item with text "Hello world" should be present

  @todo_02
  Scenario: todo_02 - removing all todo items
    Given "test-user" has at least 1 todo item
    When the user marks all todo items as completed
    And the clear completed button is pressed
    Then no todo items should display

  @todo_03
  Scenario: todo_03 - confirming the progress bar
    Given "test-user" has exactly 8 todo items
    When the user marks 4 todo items as completed
    Then the progress bar should display at 50 percent