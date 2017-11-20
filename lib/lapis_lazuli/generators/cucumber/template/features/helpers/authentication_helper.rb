module Auth

  extend LapisLazuli

  class << self

    @@user = ''

    def log_in(user, renew_session=false)
      Auth.set_role_if_not_exsist user unless user == 'super dev'
      @@user = user
      Auth.log_out if renew_session
      unless Auth.is_logged_in?(user)
        Auth.ensure_log_out
        Nav.to('login')
        browser.find(:like => [:input, :name, 'login[username]']).send_keys(Auth.get_user('username'))
        browser.find(:like => [:input, :name, 'login[password]']).send_keys(Auth.get_user('password'))
        browser.find(:like => [:input, :id, 'login-button']).click
        if !Auth.is_logged_in? user
          alert = browser.find(:like => [:div, :class, 'alert'], :throw => false)
          if alert.nil?
            error "Failed to log in user #{user}"
          else
            error "Found error while logging in #{user}: `#{alert.text}`"
          end
        end
      end
    end

    def log_out
      browser.find(:like => [:div, :id, 'accountInfo']).click
      browser.find(:like => [:a, :href, '/logout']).click
      error "Failed logging out user #{@@user}" if Auth.is_logged_in?
    end

    def ensure_log_out
      Auth.log_out if Auth.is_logged_in?
    end

    def is_logged_in?(user=nil)
      # Either look for just the avatar, or also include the user name
      selector = {:div => {:id => 'accountInfo'}}
      if !user.nil?
        selector = {:div => {:id => 'accountInfo', :text => /#{(Auth.get_user('first_name'))}/}}
      end

      Nav.to('landing') unless Nav.is_url?(browser.url)
      # Doing a quick check if either state can be confirmed
      avatar = browser.find(:selectors => [selector], :throw => false)
      if avatar.nil?
        login_input = browser.find(:like => [:input, :name, 'login[username]'], :throw => false)
        return false unless login_input.nil?
      else
        return true
      end

      Nav.to('landing')
      # Wait a moment if logged in state can be confirmed
      avatar = browser.multi_wait(
        :selectors => [selector],
        :throw => false
      )
      if avatar.nil?
        return false
      else
        return true
      end
    end

    def wait_while_logged_in
      browser.wait_until(timeout: 10, message: 'User was still logged in after waiting for 10 seconds.') {!Auth.is_logged_in?}
    end

    def get_user(field)
      data = Auth.get_data
      begin
        ret = data["users"][ENV['TEST_ENV']][ENV['BRANCH']][@@user][field]
      rescue NoMethodError => e
        if @@user == 'super dev'
          ret = data["users"][@@user][field]
        else
          p data
          error "Failed getting `users.#{ENV['TEST_ENV']}.#{ENV['BRANCH']}.#{@@user}.#{field}`: #{e.message}"
        end
      end
      return ret
    end

    def get_role_id(role)
      config("roles.#{role}")
    end

    def get_data()
      YAML.load_file "./config/users.yml"
    end

    def set_data(new_data)
      data = Auth.get_data

      require 'deep_merge'
      data.deep_merge!(new_data)

      File.open("./config/users.yml", 'w') {|f| YAML.dump(data, f)}
    end

    def set_role_if_not_exsist(role)
      begin
        data = Auth.get_data['users'][ENV['TEST_ENV']][ENV['BRANCH']][role]
        # Force error if data is nil
        raise("users.#{ENV['TEST_ENV']}.#{ENV['BRANCH']}.#{role} was nil") if data.nil?
      rescue Exception => e
        warn e.message
        start_url = browser.url
        puts "Role `#{role}` does not exist yet. Looking up a user with this role..."
        Auth.log_in('super dev')
        Nav.to('accounts')
        Auth.find_role role
        @@user = role
        puts "Role `#{role}` has been created in ./config/users.yml"
      end
    end

    def find_role(role)
      role_id = Auth.get_role_id role
      elm = browser.find(:select => {:name => 'roles'})
      begin
        elm.select(role_id.to_s)
      rescue Watir::Exception::NoValueFoundException
        error "id `#{role_id.to_s}` for `#{role}` not found in the select list. Does this role exist for `#{ENV['BRANCH']}`"
      end
      browser.find(:like => [:input, :id, 'numberFilter']).set('')
      #puts 'Looking for `edit` button in large table.. this could take a while...'
      row = browser.find(:like => [:tr, :class, 'employed employee'])
      browser.find(
        :like => [:a, :href, '/editaccount/'],
        :context => row,
        :message => "No `#{role}` found after filtering all employees."
      ).click
      username = browser.wait(:like => [:input, :id, 'user_accounts_user_name']).value
      firstname = browser.wait(:like => [:input, :id, '_first_name']).value
      cache_role(role, username, firstname)
    end

    def cache_role(role, username, firstname)
      add_data = {
        'users' => {
          ENV['TEST_ENV'] => {
            ENV['BRANCH'] => {
              role => {
                'username' => username,
                'first_name' => firstname,
                'password' => Auth.get_data['users']['default-password']
              }
            }
          }
        }
      }
      Auth.set_data add_data
    end

    def current_user()
      return @@user
    end
  end
end