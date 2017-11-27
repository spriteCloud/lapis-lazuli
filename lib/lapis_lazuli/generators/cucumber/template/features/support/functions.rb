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