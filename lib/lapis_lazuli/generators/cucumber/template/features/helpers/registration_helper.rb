module Register

  extend LapisLazuli
  class << self

    # This is a list of elements relevant for this helper.
    # The following is short notation, *only* use this if the element selector can be done in 1 line.
    # @formatter:off
    def form; browser.wait(:like => [:form, :id, 'form-register']); end
    def open_register_button; browser.find(:like => [:button, :id, 'button-register']); end
    def username_field; browser.find(:element => {:name => 'username'}, :context => Register.form); end
    def password_field; browser.find(:element => {:name => 'password'}, :context => Register.form); end
    def experience_field; browser.find(:like => [:select, :id, "register-experience"], :context => form); end
    def biography_field; browser.find(:like => [:textarea, :id, 'register-bio']); end
    def policy_checkbox; browser.find(:like => [:input, :id, 'register-complete-all']) end
    def submit_button; browser.find(:button => {:id => 'button-save'}, :context => Register.form); end
    # @formatter:on

    def gender_radio(gender)
      browser.find(
        :label => {:text => /#{gender}/i},
        :context => Register.form,
        :message => "Unable to find gender `#{gender}`, are you sure it's an option to select?"
      )
    end

    def select_experiences(*experience_list)
      experience_list.each do |exp|
        option = browser.find(
          :option => {:value => /#{exp}/i},
          :context => Register.experience_field
        )
        option.click(:control)
      end
    end

    # The following 3 functions are a typical example of something to use.
    # First a function in which you perform an action (open_something, click_something, press_something)
    def open_registration
      Register.open_register_button.click
    end

    # Second, a function that confirms that the action was successful
    def is_registration_open?
      return Register.form rescue false
    end

    # And finally as function that ensures an action was successfully completed.
    def ensure_open_registrarion
      Auth.ensure_log_out
      Register.open_registration unless Register.is_registration_open?
    end

    def fill_form
      Register.username_field.set(User.get('username'))
      Register.password_field.set(User.get('password'))
      Register.gender_radio(User.get('gender')).click
      Register.select_experiences(User.get('experience').split(','))
      Register.biography_field.set(User.get('biography'))
      Register.policy_checkbox.set((User.get('complete_all').to_i == 1))
    end

    def submit_form
      Register.submit_button.click
    end

    def register_user
      Register.fill_form
      Register.submit_form
    end

    def registration_result
      alert = browser.wait(like: [:div, :class, 'alert'], timeout: 2, throw: false)
      if alert.nil?
        return false, 'No message was displayed after registering'
      elsif !alert.text.include? User.get('username')
        return false, "An error message did display, but didn't contain the expected text: `#{alert.text}`"
      end
      return true, 'Successfully found the success message'
    end

    def ensure_registered(user)
      begin
        Auth.ensure_log_in(user)
        Auth.log_out
      rescue Exception => e
        Register.ensure_open_registrarion
        Register.register_user
      end
    end

  end
end