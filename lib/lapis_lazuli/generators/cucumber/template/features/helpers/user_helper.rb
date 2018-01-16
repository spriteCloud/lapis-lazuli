# This helper loads user data from the config files.
# After loading the data, it will overwrite certain strings, like __TIMESTAMP__ to randomize information
module User
  extend LapisLazuli

  class << self
    @@data = nil

    def load_user_data(user)
      data = config('users.default-user')
      begin
        specific_data = config("users.#{user}")
      rescue Exception => err1
        begin
          specific_data = config("users.#{ENV['TEST_ENV']}.#{user}")
        rescue Exception => err2
          error "The given user `#{user}` was not found in any of the config files:\n- #{err1.message}\n- #{err2.message}"
        end
      end
      new_data = data.merge specific_data
      @@data = replace_hash_constants(new_data)
    end

    def get(field)
      return @@data[field]
    end

    def set(field, value)
      @@data[field] = User.replace_constants(value)
    end

    # Replace random or time values of a complete hash
    def replace_hash_constants(hash)
      if hash.respond_to? :each
        new_hash = {}
        hash.each do |key, value|
          new_hash[key] = replace_constants(value)
        end
      else
        new_hash = replace_constants(hash)
      end
      return new_hash
    end

    # replace certain constants in a string, for example '_TIMESTAMP_' becomes '154875631'
    def replace_constants(value)
      if value.to_s == value
        epoch = Time.now.to_i
        alpha = number_to_letter(epoch)
        timestamp = Time.now.strftime("D%Y-%M-%d-T%H-%M-%S")

        old_val = value.to_s
        value = value.sub('_RAND_', epoch.to_s)
        value = value.sub('_TIMESTAMP_', timestamp)
        value = value.sub('_RAND-ALPHA_', alpha)
        unless value == old_val
          log.debug "#{old_val} > #{value}"
        end
      end
      return value
    end

    def number_to_letter(numbers)
      num_string = numbers.to_s
      alpha26 = ("a".."j").to_a
      letters = ''
      num_string.scan(/./).each do |number|
        letters += alpha26[number.to_i]
      end
      return letters
    end

  end
end