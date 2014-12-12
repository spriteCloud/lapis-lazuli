@har @p
Feature: HAR
When I want to test the Lapis Lazuli library
I want to run a webserver with some test files
And execute the each library function handle HAR files.

@har_01
Scenario: Goto simple HTTP site
  When I go to "http://ipecho.net/plain"
