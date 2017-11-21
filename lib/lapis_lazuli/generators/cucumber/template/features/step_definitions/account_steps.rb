# A step definition is a regex, to learn more about this go to http://rubular.com/
# The following step definition accepts both:
# - the user logs in > will use the last stored user data
# - "user-x" logs in > will load user data from config.yml
When(/^"(.*?)" logs in$/) do |user|
  user = nil if user != 'the user'
  p user
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

Then(/^the page should display as logged (in|out) state$/) do |logged|
  # Adjust variable for checking logged in or logged out state.
  if logged == 'in' and !Auth.is_logged_in?
    error 'Unable to find profile picture, the user wasnt logged in successfully'
  elsif logged == 'out' and Auth.is_logged_in?
    error 'The profile picture is present, indicating that the user did not log out successfully'
  end
end

When(/^"(.*?)" registers for a new account$/) do |user_tag|
  # pending # Write code here that turns the phrase above into concrete actions

  # Set the user data
  set_user_data(user_tag)

  # Go to the registration page
  step 'the user navigates to the "training-page" page'
  browser.find(:like => [:button, :id, 'button-register']).click

  # Fill in the form

  # Get the form container and use it as a context to find the fields
  form = browser.wait(:like => [:form, :id, 'form-register'])

  # Fill in the details
  browser.find(:element => {:name => 'username'}, :context => form).set get_user_data('username')
  browser.find(:element => {:name => 'password'}, :context => form).set get_user_data('password')

  # Select gender
  browser.find(
    :label => {:text => /#{get_user_data('gender')}/i},
    :context => form,
    :message => "Unable to find gender `#{get_user_data('gender')}`, are you sure it's an option to select??"
  ).click

  # Select experiences from the multi-select list
  multi_selector = browser.find(:like => [:select, :id, "register-experience"], :context => form)
  experiences = get_user_data('experience')
  # Experiences is a list of words comma separated, EG `Ruby,Cucumber,Watir`
  # The following function will cut text at every comma, and loop trough every separate word
  experiences.split(',').each do |exp|
    option = browser.find(
      :option => {:value => /#{exp}/i},
      :context => multi_selector
    )
    option.click
  end

  # Fill in the biagraphy
  browser.find(
    :like => [:textarea, :id, 'register-bio']
  ).send_keys(get_user_data('biography'))

  # Click the accept policy checkbox
  browser.find(:like => [:input, :id, 'register-complete-all']).click

  # Press the submit button
  browser.find(:button => {:id => 'button-save'}).click

  # Wait for the success message to display
  browser.wait(
    :like => [:div, :class, 'alert-success'],
    :message => 'The successfully registered message did not display.'
  )

  # The website we're testing on, doesn't log in the user automatically. So let's trigger that step manually
  step 'the user logs in'
end