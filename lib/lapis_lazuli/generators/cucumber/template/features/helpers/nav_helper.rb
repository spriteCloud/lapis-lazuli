# Simple helper that makes navigating using the config file easier
# It will check if a given string is a URL or a config value and goto that page accordingly
module Nav
  extend LapisLazuli
  class << self

    def to(config_page_or_url, force_refresh = false)
      url = self.set_url(config_page_or_url)
      browser.goto url unless url == browser.url and !force_refresh
      Nav.wait_for_url url
    end

    def wait_for_url(url)
      browser.wait_until(timeout: 5, message: "URL did not become `#{url}`") {
        browser.url.include? url
      }
    end

    def get_url page
      begin
        return env_or_config("pages.#{page}")
      rescue RuntimeError
        return env_or_config("pages.#{page}.path")
      end
    end

    def is_url? string
      uri = URI.parse(string)
      %w( http https ).include?(uri.scheme)
    rescue URI::BadURIError
      false
    rescue URI::InvalidURIError
      false
    end

    def set_url(config_page_or_url)
      if Nav.is_url? config_page_or_url
        return config_page_or_url
      else
        path_or_url = get_url config_page_or_url
        if Nav.is_url? path_or_url
          return path_or_url
        else
          return env('root') + path_or_url
        end
      end
    end

  end
end