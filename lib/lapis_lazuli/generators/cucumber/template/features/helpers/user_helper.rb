module User
  extend LapisLazuli

  class << self
    @@data

    def load_user_data(user)
      data = config('users.default-user')
      begin
        specific_data = config("users.#{user}")
      rescue
        specific_data = config("users.#{ENV['TEST_ENV']}.#{user}")
      end
      data.merge! specific_data
      @@data = data
    end

    def get(field)
      return @@data[field]
    end

    def set(field, value)
      @@data[field] = value
    end
  end
end