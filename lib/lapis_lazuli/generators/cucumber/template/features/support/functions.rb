# Sometimes you're repeating a piece of code over and over again.
# At that point you should consider making it a function.

def set_user_data(data)
  # If the global variable isn't set yet, it should be
  if $USER_DATA.nil?
    $USER_DATA = config("users.default-user")
  end

  # Start by getting the default user data
  default_data = config("users.default-user")

  # Then get the data from the specifically requested data
  user_data = config("users.#{data}")

  # Let the user specific data overwrite all the defaults that are set
  user_data = default_data.merge(user_data)

  # Replace all random and time values in the data
  user_data = hash_parse_data(user_data)

  # Put it in the global variable
  $USER_DATA = user_data

end

# Get the data for the requested field.
def get_user_data(field)
  return $USER_DATA[field]
end

# Replace random or time values of a complete hash
def hash_parse_data(hash)
  if hash.respond_to? :each
    new_hash = {}
    hash.each do |key, value|
      new_hash[key] = replace_value(value)
    end
  else
    new_hash = replace_value(hash)
  end
  return new_hash
end

def replace_value(value)
  epoch = Time.now.to_i
  alpha = number_to_letter(epoch)
  timestamp = Time.now.strftime("D%Y-%M-%d-T%H-%M-%S")
  value = value.to_s
  old_val = value
  value = value.sub('_rand_', epoch.to_s)
  value = value.sub('_timestamp_', timestamp)
  value = value.sub('_rand-alpha_', alpha)
  unless value == old_val
    log.debug "#{old_val} > #{value}"
  end
  return value
end