# Simple helper that makes navigating using the config file easier
# It will check if a given string is a URL or a config value and goto that page accordingly
module Nav
  extend LapisLazuli
  class << self

    # Navigates to a given URL or page.url configuration if the current URL is not the same
    # Then confirms that the new URL is loaded.
    def to(config_page_or_url, force_refresh = false)
      url = self.set_url(config_page_or_url)
      browser.goto url unless url == browser.url and !force_refresh
      Nav.wait_for_url url
    end

    # Waits until the browser URL is the same as the given URL
    def wait_for_url(url)
      browser.wait_until(timeout: 5, message: "URL did not become `#{url}`") {
        browser.url.include? url
      }
    end

    # Loads the URL from the config, prioritized from top to bottom:
    # production.pages.home
    # production.pages.home.path
    # pages.home
    # pages.home.path
    def get_url page
      begin
        return env_or_config("pages.#{page}")
      rescue RuntimeError
        return env_or_config("pages.#{page}.path")
      end
    end

    # Confirms if the given URL is a valid URL
    def is_url? string
      uri = URI.parse(string)
      %w( http https ).include?(uri.scheme)
    rescue URI::BadURIError
      false
    rescue URI::InvalidURIError
      false
    end

    # returns the expected URL
    def set_url(config_page_or_url)
      if Nav.is_url? config_page_or_url
        # Return the given URL if it alreadt is a valid URL
        return config_page_or_url
      else
        # Look for the URL in the config files
        path_or_url = get_url config_page_or_url
        if Nav.is_url? path_or_url
          # If it is a URL now, then return it
          return path_or_url
        else
          # Else add an expected 'root' to the path.
          return env('root') + path_or_url
        end
      end
    end

  end
end