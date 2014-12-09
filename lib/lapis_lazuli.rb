#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/version"
require "lapis_lazuli/lapis_lazuli"

# FIXME None of these functions are tested.

module LapisLazuli

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
  # TODO: Replace with http://watirwebdriver.com/page-performance/
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
