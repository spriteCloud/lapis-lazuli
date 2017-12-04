module Auth

  extend LapisLazuli
  class << self

    @@user = ''
    @login_page = 'training-page'

    # This is a list of elements relevant for this helper.
    # The following is short notation, *only* use this if the element selector can be done in 1 line.
    # @formatter:off
    def form_container; browser.wait(:like => [:div, :class, 'container']); end
    def username_field; form_container.input(:xpath => '//*[@id="login-username"]'); end
    def password_field; form_container.browser.input(:id => 'login-password'); end
    def login_button; browser.button(:id => 'button-login'); end
    # @formatter:on

    # Following elements that need more advanced options/search patterns
    def logged_in_element(timeout=10, throw=true)
      browser.wait(
        :like => [:a, :id, 'user_dropdown'],
        :timeout => timeout,
        :throw => throw
      )
    end

    def logged_out_element(timeout=10, throw=true)
      browser.wait(
        :like => [:form, :id, 'form-login'],
        :timeout => timeout,
        :throw => throw
      )
    end

    # Next are the functions called from the step definitions
    # `ensure_something` is best practise to be used for functions that should get the test to a certain state. For example:
    # `ensure_log_out` only logs out if you're logged in
    # `log_out` will blindly try to log out and fail if you're already logged out
    def ensure_log_out
      Nav.to('training-page')
      if Auth.is_logged_in?
        Auth.log_out
        if Auth.is_logged_in?
          error 'Page did not display in logged out state after logging out'
        end
      end
    end

    def ensure_log_in(user='default-user')
      Nav.to('training-page')
      unless Auth.is_logged_in?(user)
        Auth.ensure_log_out
        Auth.log_in(user)
        unless Auth.is_logged_in?(user)
          error "Failed to log in `#{user}`."
        end
      end
    end

    def is_logged_in?(user=nil)
      if Auth.logged_out_element(0, false)
        return false
      end
      if user.nil?
        return !Auth.logged_in_element(5, false).nil?
      else
        User.load_user_data(user)
        elm = Auth.logged_in_element(5, false)
        if elm.nil?
          return false
        else
          return elm.span(:class => ['username', 'ng-binding']).text == User.get('username')
        end
      end
    end

    def log_out
      Auth.logged_in_element.click
      dropdown = browser.wait(:like => [:ul, :class, 'dropdown-menu'])
      browser.find(
        :like => [:a, :id, 'link-logout'],
        :context => dropdown
      ).click
    end

    def log_in(user=nil, renew_session=false)
      User.load_user_data(user) unless user.nil?

      Nav.to('training-page')
      Auth.username_field.to_subtype.set(User.get('username'))
      Auth.password_field.to_subtype.set(User.get('password'))
      Auth.login_button.click

      unless Auth.is_logged_in? user
        alert = browser.find(:like => [:div, :class, 'alert'], :throw => false)
        if alert.nil?
          error "Failed to log in user #{user}"
        else
          alert.flash
          error "Found error while logging in #{user}: `#{alert.text}`"
        end
      end
    end
  end
end