#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
module BrowserModule
  module Remote
    # Convert settings to a valid remote driver argument
    #
    # Features:
    #  - settings hash can be case insensitive "URL","Url", "url"
    #  - caps.firefox_profile will be converted to a Selenium::WebDriver::Firefox::Profile
    #  - caps.proxy / caps.firefox_profile.proxy will be converted to a Selenium::WebDriver::Proxy
    #  - Hashes can have a String or a Symbol as key
    #
    # Example:
    #  args = remote_browser_config(
    #   {
    #     "url"=>"http://test.com",
    #     "user"=>"user21",
    #     "password"=>"jehwiufhewuf",
    #     "caps"=> {
    #       "browser_name"=>"firefox",
    #       "version"=>"37",
    #       "firefox_profile"=>{
    #         "plugin.state.flash"=>0,
    #         "secure_ssl"=>true,
    #         "proxy"=>{"http"=>"test.com:9000"}
    #       },
    #       "proxy"=>{:http=>"test.com:7000"},
    #       :css_selectors_enabled => true
    #     }
    #   })
    #  Watir::Browser.new :remote, args
    def remote_browser_config(settings)
      require "uri"
      require "selenium-webdriver"

      if !settings.is_a? Hash
        world.error("Missing Remote Browser Settings")
      end

      # Fetch the URl
      url = hash_get_case_insensitive(settings,"url")

      # Test if its a valid URL
      if not (url.to_s =~ /\A#{URI::regexp(["http", "https"])}\z/)
        raise "Incorrect Remote URL: '#{url.to_s}'"
      end

      # Create URI object
      uri = URI.parse(url)

      # Add user if needed
      user = hash_get_case_insensitive(settings,"user")
      if !user.nil?
        uri.user = user
      end

      # Add password if needed
      password = hash_get_case_insensitive(settings,"password")
      if !password.nil?
        uri.password = password
      end

      # Create capabil
          # Check ities
      caps = Selenium::WebDriver::Remote::Capabilities.new
      # Fetch the settings
      caps_settings = hash_get_case_insensitive(settings,"caps")

      # If we have settings
      if !caps_settings.nil? and caps_settings.is_a? Hash
        caps_settings.each do |key, val|
          # Convert to proxy
          if key.to_s == "proxy"
            set_proxy(caps, val)
          # Convert to FF profile
          elsif key.to_s == "firefox_profile"
            profile = Selenium::WebDriver::Firefox::Profile.new
            # Set all the options
            val.each do |fkey, fval|
              # Convert to proxy
              if fkey.to_s == "proxy"
                set_proxy(profile,fval)
              else
                set_key(profile, fkey, fval)
              end
            end
            # Set the profile
            caps[:firefox_profile] = profile
          else
            # Use set_key to assign the key
            set_key(caps, key, val)
          end
        end
      end

      world.log.debug("Using remote browser: #{url} (#{uri.user}) #{caps.to_json}")

      return {
        :url => uri.to_s,
        :desired_capabilities => caps
      }
    end

    private
      def hash_get_case_insensitive(hash, key)
        new_key = hash.keys.find {|e| e.to_s.casecmp(key.to_s) == 0}
        if new_key.nil?
          return nil
        end
        return hash[new_key]
      end

      # Sets a selenium proxy to the object
      def set_proxy(object, hash)
        proxy = Selenium::WebDriver::Proxy.new
        hash.each do |key, val|
          set_key(proxy, key, val)
        end
        object.proxy = proxy
      end

      # Uses function based on key or key itself to store the value in the object
      def set_key(object, key, val)
        if object.respond_to? "#{key}="
          object.send("#{key}=", val)
        else
          object[key] = val
        end
      end

  end # module Remote
end # module BrowserModule
end # module LapisLazuli
