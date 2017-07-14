#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
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
        dir = world.env_or_config("screenshot_dir")

        # Generate the file name according to the new or old scheme.
        case world.env_or_config("screenshot_scheme")
          when "new"
            # For non-cucumber cases: we don't have world.scenario.data
            if not world.scenario.data.nil?
              name = world.scenario.id
            end
            # FIXME random makes this non-repeatable, sadly
            name = "#{world.scenario.time[:iso_short]}-#{@browser.object_id}-#{name}-#{Random.rand(10000).to_s}.png"
          else # 'old' and default
            # For non-cucumber cases: we don't have world.scenario.data
            if not world.scenario.data.nil?
              name = world.scenario.data.name.gsub(/^.*(\\|\/)/, '').gsub(/[^\w\.\-]/, '_').squeeze('_')
            end
            name = world.time[:timestamp] + "_" + name + '.png'
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
        dir = world.env_or_config("screenshot_dir")
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
          # First make sure the window size is the full page size
          if world.env_or_config("screenshots_height") == 'full'
            original_height = @browser.window.size.height
            width = @browser.window.size.width
            target_height = @browser.execute_script('
              var body = document.body,
              html = document.documentElement;
              return Math.max( body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight );
            ')
            if target_height > original_height
              @browser.window.resize_to(width, target_height)
            end
          end

          # Save the screenshot
          @browser.screenshot.save fileloc

          if world.env_or_config("screenshots_height") == 'full'
            if target_height > original_height
              @browser.window.resize_to(width, original_height)
            end
          end
          world.log.debug "Screenshot saved: #{fileloc}"

          # Try to store the screenshot name
          if world.respond_to? :annotate
            world.annotate :screenshot => fileloc
          end
        rescue RuntimeError => e
          world.log.debug "Failed to save screenshot to '#{fileloc}'. Error message #{e.message}"
        end
        return fileloc
      end
    end # module Screenshots
  end # module BrowserModule
end # module LapisLazuli
