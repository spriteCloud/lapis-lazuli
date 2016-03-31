#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2016 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
module DriverModule

  ##
  # Module with error handling related functionality (World)
  module Error
    ##
    # Does this page have errors?
    # Checks the pagetext for error_strings that are specified in the config
    def has_error?
      errors = self.get_html_errors
      js_errors = self.get_js_errors
      if not js_errors.nil?
        errors += js_errors
      end

      if errors.length > 0 or self.get_http_status.to_i > 299
        errors.each do |error|
          if error.is_a? Hash
            world.log.debug("#{error["message"]} #{error["url"]} #{error["line"]} #{error["column"]}\n#{error["stack"]}")
          else
            world.log.debug("#{error}")
          end
        end
        return true
      end
      return false
    end


    ##
    # Retrieve errors from HTML elements, using the error_strings config
    # variable
    def get_html_errors
      result = []
      # Need some error strings
      if world.has_env_or_config?("error_strings")
        begin
          # Get the HTML of the page
          page_text = @driver.html
          # Try to find all errors
          world.env_or_config("error_strings").each {|error|
            if page_text.include? error
              # Add to the result list
              result.push error
            end
          }
        rescue RuntimeError => err
          # An error?
          world.log.debug "Cannot read the html for page #{@driver.url}: #{err}"
        end
      end
      # By default we don't have errors
      return result
    end


    ##
    # If the proxy is supported, use it to retrieve JS errors.
    def get_js_errors
      return self.driver.execute_script <<-JS
        try {
          return lapis_lazuli.errors;
        } catch(err){
          return null;
        }
      JS
    end


    ##
    # If the proxy is supported, use it get the HTTP status code.
    def get_http_status
      return self.driver.execute_script <<-JS
        try{
          return lapis_lazuli.http.statusCode;
        } catch(err){
          return null;
        }
      JS
    end

  end # module Error
end # module DriverModule
end # module LapisLazuli
