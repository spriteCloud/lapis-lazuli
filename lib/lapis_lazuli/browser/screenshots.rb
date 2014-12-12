#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
module BrowserModule

  ##
  # Screenshot functionality for browser
  module Screenshots
    ##
    # Returns the name of the screenshot, if take_screenshot is called now.
    def screenshot_name(suffix="")
      dir = @ll.env_or_config("screenshot_dir")

      # Generate the file name according to the new or old scheme.
      name = nil
      case @ll.env_or_config("screenshot_scheme")
      when "new"
        # FIXME random makes this non-repeatable, sadly
        name = "#{@ll.scenario.time[:iso_short]}-#{@ll.scenario.id}-#{Random.rand(10000).to_s}.png"
      else # 'old' and default
        name = @ll.scenario.data.name.gsub(/^.*(\\|\/)/, '').gsub(/[^\w\.\-]/, '_').squeeze('_')
        name = @ll.time[:timestamp] + "_" + name + '.png'
      end

      # Full file location
      fileloc = "#{dir}#{File::SEPARATOR}#{name}"

      return fileloc
    end

    ##
    # Taking a screenshot of the current page.
    # Using the name as defined at the start of every scenario
    def take_screenshot(suffix="")
      # If the target directory does not exist, create it.
      dir = @ll.env_or_config("screenshot_dir")
      begin
        Dir.mkdir dir
      rescue SystemCallError => ex
        # Swallow this error; it occurs (amongst other situations) when the
        # directory exists. Checking for an existing directory beforehand is
        # not concurrency safe.
      end

      fileloc = self.screenshot_name(suffix)

      # Write screenshot
      begin
        # Save the screenshot
        @browser.screenshot.save fileloc
        @ll.log.debug "Screenshot saved: #{fileloc}"
      rescue RuntimeError => e
        @ll.log.debug "Failed to save screenshot to '#{fileloc}'. Error message #{e.message}"
      end
      return fileloc
    end
  end # module Screenshots
end # module BrowserModule
end # module LapisLazuli
