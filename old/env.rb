################################################################################################
# Property of spriteCloud.com (R)
# Author: Mark Barzilay. For info and questions: barzilay@spritecloud.com
################################################################################################
require 'rubygems'
#require 'ruby-debug'
require 'selenium-webdriver'
require 'watir-webdriver'
require 'watir-webdriver-performance'
#require 'watir-scroll' # Gem not supported by all servers, removed for now.
require "watir-webdriver/extensions/alerts"
require 'logger'
require 'uri'
require 'time'
load 'features/support/methods.rb'
load 'features/support/speedtest.rb'

###################################################################################
# Start the logger
class LogWrapper
  def initialize(name)
    @filename = name
    @log = Logger.new(@filename)
  end

  def exception(message, ex)
    self.error("#{message} got #{ex.message}:\n#{ex.backtrace.join("\n")}")
  end

  def method_missing(meth, *args, &block)
    if @log.respond_to? meth
      if args.length > 1
        STDOUT.write("#{meth}: #{args}\n")
      else
        STDOUT.write("#{meth}: #{args[0]}\n")
      end
      STDOUT.flush()
      @log.send(meth.to_s, *args, &block)
    end
  end
end # LogWrapper
$log = LogWrapper.new('log/selenium.log')


###################################################################################
# Read the config file (load config_local.yml if it exists)
begin
    ALL_CONFIGS = YAML.load_file("config/config_local.yml")
rescue
    ALL_CONFIGS = YAML.load_file("config/config.yml")
end

###################################################################################
# Load the global variables
$environment                        = ENV['TEST_ENV'] || ALL_CONFIGS['default_env']
$make_screenshot_on_failed_scenario = ALL_CONFIGS['make_screenshot_on_failed_scenario']

CONFIGS = ALL_CONFIGS[$environment]
$STEP_PAUSE_TIME = ALL_CONFIGS['step_pause_time'] rescue STEP_PAUSE_TIME = 0
$SITE            = CONFIGS['home']
$SCREENSHOTS_DIR = ALL_CONFIGS['screenshots_dir']
$T_START         = Time.now
$CURRENT_TIME    = Time.now
$LOADTIMES       = {}
$PAGE_CONTENT    = {}
$XML_DATA        = {}

###################################################################################
# Launch the browser. Can be firefox, ie, chrome, safari (only tested on firefox)
$WEB_DRIVER      = ENV['BROWSER'] || 'firefox'

if $WEB_DRIVER == 'firefox'
    $profile = Selenium::WebDriver::Firefox::Profile.new
    #$profile.native_events = false
    #$profile['general.useragent.override'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:11.0)11 Gecko/20100101 Firefox/11.0, spriteCloud WebAssurance"

    #BETA: Add JS error detextion to the profile!
    #$profile.add_extension "setup/JSErrorCollector.xpi" rescue p "Cannot add JSErrorCollector.xpi to profile"
end

if $WEB_DRIVER == 'chrome'
    BROWSER = Watir::Browser.new :chrome, :switches => %w[ --test-type browser --enable-logging --v=5 ]
else
    begin
        if $profile.nil?
          BROWSER = Watir::Browser.new $WEB_DRIVER
        else
          BROWSER = Watir::Browser.new $WEB_DRIVER, :profile => $profile
        end
    rescue StandardError => e
        $log.exception("Trying to create browser with profile", e)
        BROWSER = Watir::Browser.new $WEB_DRIVER
    end
end

#Lets maximize the screen
begin
    width = 1034
    height = 706
    if $WEB_DRIVER == 'chrome'
      BROWSER.window.when_present.resize_to(width, height)
      BROWSER.window.move_to(0, 0)
    else
      BROWSER.driver.manage.window.resize_to(width, height)
      BROWSER.driver.manage.window.move_to(0, 0)
    end
rescue StandardError => e
  $log.exception("Trying to resize browser window", e)
end

# HTTP authentication depricated, our IP-Addresses are now whitelisted.
#Navigate to an https location to make sure we do not get the basic http auth later.
#unless $environment == "production"
#    if $WEB_DRIVER == 'ie'
#        matches = CONFIGS['http_login'].match(/(http(?:s?)*:\/\/)(.*?):(.*?)@(.*)/)
#        url = matches[1]+matches[4]
#        user = matches[2]
#         pass = matches[3]
#         BROWSER.goto url
#         sleep 1
#         BROWSER.window.send_keys(user, :tab, pass, :enter)
#     else
#         BROWSER.goto CONFIGS['http_login']
#     end
# end

###################################################################################
# Get the software versions of the application used in previous runs
ALL_VERSION_INFO = YAML.load_file("config/app_versions.yml") rescue ALL_VERSION_INFO = {}
ALL_VERSION_INFO = {} unless ALL_VERSION_INFO

$VERSION_INFO = get_software_version_info()
p $VERSION_INFO
ALL_VERSION_INFO[$environment] = $VERSION_INFO
f                              = File.open("config/app_versions.yml", 'w')
f.write(ALL_VERSION_INFO.to_yaml)
f.close
$CURRENT_TIMESTAMP       = Time.now.strftime('%y%m%d_%H%M%S')
$CURRENT_EPOCH_TIMESTAMP = Time.now.to_i.to_s

# We need to store the versions as a string so we can use it for a cucumber command line variable
begin
    VERSION_CMD_VARIABLE = "#{$VERSION_INFO.keys.first}: #{$VERSION_INFO[$VERSION_INFO.keys.first]}"
    File.open("config/APP_VERSIONS", 'w') { |f| f.write(VERSION_CMD_VARIABLE) }
rescue StandardError => e
    $log.exception("Trying to read app versions", e)
end

# Add to log
$log.debug "Testrun: \n\t environment: \t\t #{$environment} \n\t Browser: \t\t #{ENV['BROWSER'] || 'firefox'}"
unless $VERSION_INFO.empty?
    $VERSION_INFO.each_key do |key, value|
        $log.debug "\t#{key} version: #{$VERSION_INFO[key]}"
    end
end

# A method to check if the page contains an error
def error_on_page?
    #return error box content if it exists
    begin
        page_text = BROWSER.html
        ALL_CONFIGS['error_strings'].each do |error|
          match = page_text.scan(error)[0]
          if match and !match.empty?
            return match
          end
        end
    rescue
        $log.debug "Cannot read html for page #{BROWSER.url}"
    end
    return nil
end

def get_error_box_content()
    begin
        error_box = BROWSER.p(:class => /box-notice .* error/)
        if error_box.exists? and error_box.visible?
          if error_box.text and !error_box.text.empty?
            return error_box.text
          end
        end
    rescue
    end

    return nil
end

def get_js_errors()
    #check for JS errors!:
    begin
        jserror_descriptions = ""
        jserrors = BROWSER.execute_script("return window.JSErrorCollector_errors.pump()")
        jserrors.each do |jserror|
            $log.debug "ERROR: JS error detected on #{BROWSER.url}:\n#{jserror["errorMessage"]} (#{jserror["sourceName"]}:#{jserror["lineNumber"]})"
            jserror_descriptions += "JavaScript error(s) detected:
#{jserror["errorMessage"]} (#{jserror["sourceName"]}:#{jserror["lineNumber"]})
"
        end
        return jserror_descriptions
    rescue StandardError => e
        $log.exception("Checking for JS errors", e)
        return nil
    end
    return nil
end

# Actions that will happen before every scenario
Before do |scenario|
    # Scenario.name contains the table cells for scenario outline examples.
    # That means we're in such a situation if the scenario name starts with a '|'
    if /^ |/ =~ scenario.name
        locale = nil

        cells = scenario.name.split(/\|/)
        cells.each do |cell|
            # We know that for G-Star, locales are of the form xx_xx, so we can figure
            # out if a cell contains a locale string.
            if / *[a-z][a-z]_[a-z][a-z] */ =~ cell
                locale = cell.strip
                break
            end
        end

        # If we have a locale, we can deliberately log out the browser before even
        # clearing cookies, by appending /account/logout to the base URL.
        # After logging out and being redirected cookies are cleared and the membership cookie is added to
        # prevent the subscription pop-up to appear
        if CONFIGS[locale]
            url = CONFIGS[locale] + "/account/logout"
            BROWSER.goto url
        end
    end

    #TODO: Repetitive code for every scenario has to be made more efficient and reliable
    if $WEB_DRIVER != 'ie'
        BROWSER.cookies.clear rescue $log.debug "unable to clear cookies"
        BROWSER.cookies.add('membership-subscribe-dialog-presented', 'true', :path => '/', :expires => Time.new(2020))
        BROWSER.cookies.add('membership-subscribe-dialog-time-out', 'Wed Sep 17 2020 14:28:47 GMT+0200', :path => '/', :expires => Time.new(2020))
    end
    sleep 1
    closebutton = BROWSER.a(:class => /localeSelector-closeButton/)
    closebutton.fire_event('onClick') rescue ''
    closebutton = BROWSER.a(:class => /dialog-closeButton/)
    closebutton.fire_event('onClick') rescue ''
    closebutton = BROWSER.a(:id => 'hide-cookie')
    closebutton.fire_event('onClick') rescue ''

    $CURRENT_TIMESTAMP       = Time.now.strftime('%y%m%d_%H%M%S')
    $CURRENT_EPOCH_TIMESTAMP = Time.now.to_i.to_s

    $scenario_name = ''
    time_string    = $T_START.strftime('%y%m%d_%H%M%S')
    $scenario_name = scenario.name
    $scenario_name = $scenario_name.gsub /^.*(\\|\/)/, ''
    # Finally, replace all non alphanumeric, underscore or periods with underscore
    $scenario_name = $scenario_name.gsub /[^\w\.\-]/, '_'
    # Lets 'sqeeze all the multiple '_'s to just one '_' each :)
    $scenario_name = $scenario_name.squeeze('_')
    $scenario_name = time_string + "_" + $scenario_name
end

# This is executed after every scenario. Update loadtimes if they are given
After do |scenario|
    if scenario.failed? and $make_screenshot_on_failed_scenario
        take_screenshot()
    end
    encoded_img = BROWSER.driver.screenshot_as(:base64)
    embed("data:image/png;base64,#{encoded_img}", 'image/png')
end

#Using for debug purposes
AfterStep('@pause') do
    print "Press Return to continue"
    STDIN.getc
end

# This is executed after every step. Basically the step is failing,
# if the page contains one of the predefined strings (ERROR_STRINGS)
#The site might also contain an error box. We give feedback when this is detected.
AfterStep do |scenario|
  # Try to detect errors in various ways
  errors_on_page    = error_on_page?
  error_box_content = get_error_box_content()

  # This is just a boolean flag, and doesn't contain anything.
  errors_found = (!errors_on_page.nil? or !error_box_content.nil?)

  # Scenario failed - either cucumber detected it, or we did by finding errors
  if scenario.failed? or errors_found
    # Construct message, if we have one.
    message = ""

    if errors_on_page
      message = errors_on_page
    end

    if error_box_content
      message << "\nError Box: #{error_box_content}"
    end

    # Construct exception
    problematic_page = BROWSER.url

    if message.empty?
      message = "Unknown errors found on #{problematic_page}. Perhaps the URL is not reachable?"
    else
      message = "#{message} found on #{problematic_page}"
    end

    raise message
  end

  # What's this for anyway, other than slowing stuff down?
  sleep $STEP_PAUSE_TIME
end

# Closing the browser after the test, no reason to leave them lying around
at_exit do
  # Doesn't work for chrome, for some reason - or not always.
  $log.info "About to close/quit browser '#{BROWSER}'..."
  begin
    BROWSER.close
  rescue Timeout::Error => e
    $log.exception("Trying to close browser", e)
    begin
      BROWSER.quit
    rescue StandardError => e2
      $log.exception("Trying to quit browser", e2)
    end
  end
end
