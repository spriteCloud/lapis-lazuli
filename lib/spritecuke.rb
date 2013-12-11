#################################################################################
# Copyright 2013,2014 spriteCloud B.V. All rights reserved.
# Author: "Mark Barzilay" <mark@spritecloud.com>

require "spritecuke/version"

# FIXME None of these functions are tested.

module Spritecuke

  # Creating a link for easy reporting afterwards
  def create_link(name, url)
      #Lets just send the url without the parameters to prevent html display problems
      "<a href='#{url}' target='_blank'>#{name}</a>"
  end
  
  # Taking a screenshot of the current page. Using the name as defined at the start of every scenario
  def take_screenshot()
    begin
      $BROWSER.driver.save_screenshot($SCREENSHOTS_DIR + '/' + $scenario_name + '.jpg')
     $log.debug "Screenshot saved: #{$SCREENSHOTS_DIR + '/' + $scenario_name + '.jpg'}"
    rescue Exception => e
      puts "Failed to save screenshot. Error message #{e.message}"
      $log.debug "Failed to save screenshot. Error message #{e.message}"
    end
  end
  
  # Waits until the string is found with a maximum waiting time variable
  def wait_until_text_found(text, wait_time = 10)
    starttime = Time.now
  
    while Time.now-starttime<wait_time
      if $BROWSER.html.include?(text)
        return true
      end
      sleep 0.5
    end
    
    return false
  end
  
  # General function that can retrieve an element with a given attibute (e.g. class or id) and value
  def get_element(attribute, value, wait_time = 5)
    wait_until_text_found(value, wait_time)
  
    starttime = Time.now
    while Time.now-starttime < wait_time
      begin
        if $BROWSER.element(:xpath =>  "//*[contains(@#{arg1}, '#{arg2}')]").exist?
          return $BROWSER.element(:xpath =>  "//*[contains(@#{arg1}, '#{arg2}')]")
        end
      rescue Exception => e
        p e.message
      end
    end
  
    return nil
  end
  
  # General function that tries to find a button, using the most common button layouts.
  # Waits until the button is found with a maximum waiting time variable.
  def find_button(text, wait_time = 5)
    wait_until_text_found(text, wait_time)
  
    # First try to find it quick and return the element
    return $BROWSER.button(:text => text) if $BROWSER.button(:text => text).present?
    return $BROWSER.input(:value => text) if $BROWSER.input(:value => text).present?
    return $BROWSER.input(:title => text) if $BROWSER.input(:title => text).present?
  
    buttons = $BROWSER.buttons(:text => /#{text}/i)
    buttons.each do |button|
      if button.visible?
        $log.debug "Found '#{button.text}' by case insensitive regular expression '#{text}'"
        return button
      end
    end
    
    buttons = $BROWSER.elements(:class => /button/, :text => /#{text}/i)
    buttons.each do |button|
      if button.visible?
        return button
      end
    end
    
    #Perhaps an element withing the button contains the button text
    buttons = $BROWSER.buttons
    buttons.each do |button|
      if button.element(:text => /#{text}/i).exist?
        return button
      end
    end
    
    if ['Login', 'login', 'Log in', 'log in', 'Inloggen', 'inloggen'].include? text
      buttons = $BROWSER.buttons(:text => /log/i)
      buttons.each do |button|
        if button.visible?
          return button
        end
      end
    end
  
    return nil
  end
  
  # Button as span also occurs often.
  def find_span_button_by_title(title)
    all_save_buttons = $BROWSER.spans(:title => title)
    all_save_buttons.each do |button|
      if button.visible?
        return button
      end
    end
    return nil
  end
  
  # Gently process (make a screenshot, report the error) if an element is not found
  def handle_element_not_found(element, name)
    take_screenshot()
    feedback = "#{element}: '#{name}' not found on #{create_link('page', $BROWSER.url)}"
  
    if ENV['BREAKPOINT_ON_FAILURE']
      p feedback
      require 'debugger'; debugger
    end
  
    raise feedback
  end
  
  # Gently process (make a screenshot, report the error) if an element is found unexpectedly
  def handle_element_found(element, name)
    take_screenshot()
    feedback = "#{element}: '#{name}' found on #{create_link('page', $BROWSER.url)}"
    
    if ENV['BREAKPOINT_ON_FAILURE']
      p feedback
      require 'ruby-debug'
      breakpoint
    end
  
    raise feedback
  end
  
  
  # Using strings TIMESTAMP or EPOCH_TIMESTAMP in your tests, converts that string to a time value.
  def update_variable(variable)
    
    if variable.include?("EPOCH_TIMESTAMP")
      variable = variable.gsub!("EPOCH_TIMESTAMP", $CURRENT_EPOCH_TIMESTAMP.to_i.to_s)
    end
    
    if variable.include?("TIMESTAMP")
      variable = variable.gsub!("TIMESTAMP", $CURRENT_TIMESTAMP)
    end
  
    variable
  end
  
  # Closes the browser and creates a new BROWSER instance.
  # This is useful when a scenario experiences a popup that it cannot close or process, and the testrun is stuck
  def restart_browser()
    $log.debug "Restarting browser in scenario: #{$scenario_name}"
    $BROWSER.close
    # Needs to be a global value, else we get a dynamic constant assignment error
    # Most ideal situation is if the BROWSER instance is already a global variable, but this works
    case $WEB_DRIVER
      when 'firefox'
        $NEW_BROWSER = Watir::Browser.new :firefox
      when 'chrome'
        # Check Platform running script
        if RUBY_PLATFORM.downcase.include?("linux")
          Watir::Browser::Chrome.path = "/usr/lib/chromium-browser/chromium-browser"
        end
        $NEW_BROWSER = Watir::Browser.new :chrome
      when 'safari'
        $NEW_BROWSER = Watir::Browser.new :safari
      when 'ie'
        require 'rbconfig'
        if (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
          $NEW_BROWSER = Watir::Browser.new :ie
        else
          raise "You can't run IE tests on non-Windows machine"
        end
      when 'ios'
        if RUBY_PLATFORM.downcase.include?("darwin")
          $NEW_BROWSER = Watir::Browser.new :iphone
        else
          raise "You can't run IOS tests on non-mac machine"
        end
      else
        # Defaults to firefox
        $log.info("Couldn't determine the browser to use. Using firefox")
        $NEW_BROWSER = Watir::Browser.new :firefox
    end
    $NEW_BROWSER.goto $SITE
    return $NEW_BROWSER
  end
  
  # Method is the one making the actual HTTP request
  def get_xml_data(url)
    require 'net/http'
    require 'xmlsimple'
    
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = XmlSimple.xml_in(response)
  end
  
  # Template. This function is custom development and differs per web application
  def get_software_version_info()
    version_info = {}
  end
  
  # General function that finds a text field uses the most common input field structures
  # First tries to find exact matches, but also looks at case insensitive near matches
  def find_input_field(field_label)
  
    return $BROWSER.text_field(:name => field_label) if $BROWSER.text_field(:name => field_label).present?
  
    text_fields = $BROWSER.text_fields(:name => field_label)
    text_fields.each do |text_field|
      return text_field unless !text_field.visible?
    end
    
    text_fields = $BROWSER.text_fields(:name => /#{field_label}/i)
    text_fields.each do |text_field|
      return text_field unless !text_field.visible?
    end
    
    #if it is a search query, try to find it by using an input field with value 'query'
    if ['vind', 'search', 'zoeken'].include? field_label.downcase
      text_fields = $BROWSER.text_fields(:name => /q/)
      text_fields.each do |text_field|
        return text_field unless !text_field.visible?
      end
  
      text_fields = $BROWSER.text_fields(:name => "keyword")
      text_fields.each do |text_field|
        return text_field unless !text_field.visible?
      end
    end
    
    return nil
  end
  
  # General function that finds a link by using the most common structures
  def find_link(text)
    wait_until_text_found(text, 5)
    
    return $BROWSER.a(:text => text) if $BROWSER.a(:text => text) and $BROWSER.a(:text => text).visible? rescue ""
    
    links = $BROWSER.as(:text => text)
    links.each do |link|
      if link.visible?
        return link
      end
    end
    
    #try to find it case insensitive
    links = $BROWSER.as(:text => /#{text}/i)
    links.each do |link|
      if link.visible?
        $log.debug "Found '#{link.text}' by case insensitive regular expression '#{text}'"
        return link
      end
    end
    
    return nil
  end
  
  # General basic function that reloads the url and returns the loadtime
  def get_loadtime(url)
    starttime = Time.now
    $BROWSER.goto url
    endtime = Time.now-starttime
  end
  
  # Finds a select list by using the label
  def find_select_list(label)
    return $BROWSER.select_list(:id => label) if $BROWSER.select_list(:id => label).exist?
    raise handle_element_not_found("select_list", label)
  end

end
