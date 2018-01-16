# A step definition is a regex, to learn more about this go to http://rubular.com/
# More info: https://github.com/cucumber/cucumber/wiki/Step-Definitions

# The following step definition accepts both:
# - the user logs in > will use the last stored user data
# - "user-x" logs in > will load user data from config.yml
When(/^"?(.*?)"? logs in$/) do |user|
  user = nil if user == 'the user'
  # Check out ./features/helpers/ for the function being called
  Auth.log_in(user)
end

When(/^the user clicks on the logout button$/) do
  Auth.log_out
end

Given(/^the user is logged out$/) do
  Auth.ensure_log_out
end

Given(/^"(.*?)" is logged in$/) do |user|
  Auth.ensure_log_in(user)
end

# One step definition that handles both the logged in as the logged out state
Then(/^the page should display as logged (in|out) state$/) do |logged|
  # Adjust variable for checking logged in or logged out state.
  if logged == 'in' and !Auth.is_logged_in?
    error 'Unable to find profile picture, the user wasnt logged in successfully'
  elsif logged == 'out' and Auth.is_logged_in?
    error 'The profile picture is present, indicating that the user did not log out successfully'
  end
end

# A static way to write your step definition
When 'the user clicks on the registration button' do
  Register.open_registration
end

When 'the registration form should display' do
  error 'The registration form did not display.' unless Register.is_registration_open?
end

Given /^"(.*?)" has the registration form opened$/ do |user|
  User.load_user_data(user)
  Register.ensure_open_registrarion
end

Given /^"(.*?)" has registered a new account$/ do |user|
  Register.ensure_registered(user)
end

When 'the user completes registration' do
  Register.register_user
end

Then 'the successful registration message should display' do
  result, message = Register.registration_result
  error message unless result
end