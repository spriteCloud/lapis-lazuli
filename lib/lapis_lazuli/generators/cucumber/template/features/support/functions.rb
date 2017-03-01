# Sometimes you're repeating a piece of code over and over again.
# At that point you should consider making it a function.

# Define a the user data to use.
def set_user_data(data)
  # Load the user data from the configuration file
  user_data = config("users.#{data}")

  # Replace all random and time values in the data
  user_data = replace_hash_constants(user_data)

  # Put it in the global variable
  $USER_DATA = user_data

end

# Get the data for the requested field.
def get_user_data(field)
  # Make sure the user data is set before this function was called.
  if $USER_DATA.nil?
    error "No user data was set when get_user_data() was called for #{field}."
  end
  # Check if the specifically requested field is defined
  if $USER_DATA[field].nil?
    error "The requested user data `#{field}` does not exist. Are you sure it's defined in ./config/config.yml ?"
  end
  # Return te requested data
  return $USER_DATA[field]
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
  epoch = Time.now.to_i
  alpha = number_to_letter(epoch)
  timestamp = Time.now.strftime("D%Y-%M-%d-T%H-%M-%S")
  value = value.to_s
  old_val = value
  value = value.sub('_RAND_', epoch.to_s)
  value = value.sub('_TIMESTAMP_', timestamp)
  value = value.sub('_RAND-ALPHA_', alpha)
  unless value == old_val
    log.debug "#{old_val} > #{value}"
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