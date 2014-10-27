################################################################################################
# Property of spriteCloud.com (R)
# Author: Mark Barzilay. For info and questions: barzilay@spritecloud.com
################################################################################################

#Creating a link for easy debugging afterwards
def create_link(name, url)
    #Lets just send the url without the parameters to prevent html display problems
    "<a href='#{url}' target='_blank'>#{name}</a>"
end

#Taking a screenshot of the current page
def take_screenshot()
  BROWSER.driver.save_screenshot($SCREENSHOTS_DIR + '/' + $scenario_name + '.jpg')
  $log.debug "Screenshot saved: #{$SCREENSHOTS_DIR + '/' + $scenario_name + '.jpg'}"
end

# Waits untill the string is found with a maximum waiting time variable
def wait_until_text_found(text, wait_time = 5)
  starttime = Time.now
  while Time.now-starttime<wait_time
    if BROWSER.html.include?(text)
      return true
    end
    sleep 0.5
  end
  
  return false
end

# Waits untill the string is found in span class="price" with a maximum waiting time variable
def wait_until_price_found(text, wait_time = 5)
  starttime = Time.now
  while Time.now-starttime<wait_time
    prices = BROWSER.spans(:class => "price")
	prices.each do | price |
		return true if price.html.downcase.include?(text.downcase)
      
    end
    sleep 0.5
  end
  
  return false
end

# Waits untill the button is found with a maximum waiting time variable
def find_button(text, wait_time = 5)
  wait_until_text_found(text, wait_time)

  return BROWSER.button(:text => text) if BROWSER.button(:text => text).present?
  return BROWSER.button(:name => text) if BROWSER.button(:name => text).present?
  return BROWSER.input(:value => text) if BROWSER.input(:value => text).present?
  return BROWSER.input(:title => text) if BROWSER.input(:title => text).present?
  return BROWSER.input(:title => text) if BROWSER.input(:title => text).present?

  buttons = BROWSER.buttons(:text => /#{text}/i)
  buttons.each do |button|
    if button.visible?
      $log.debug "Found '#{button.text}' by case insensitive regular expression '#{text}'"
      return button
    end
  end
  
  buttons = BROWSER.elements(:class => /button/, :text => /#{text}/i)
  buttons.each do |button|
    if button.visible?
      return button
    end
  end
  
  #Perhaps an element withing the button contains the buttontext  
  buttons = BROWSER.buttons
  buttons.each do |button|
    if button.element(:text => /#{text}/i).exist?
      return button
    end
  end
  
  if ['Login', 'login', 'Log in', 'log in', 'Inloggen', 'inloggen'].include? text
    buttons = BROWSER.buttons(:text => /log/i)
    buttons.each do |button|
      if button.visible?
        return button
      end
    end
  end

  return nil
end

def find_span_button_by_title(title)
  all_save_buttons = BROWSER.spans(:title => title)
  all_save_buttons.each do |button|
    if button.visible?
      return button
    end
  end
  return nil
end
  
def get_widget_id(title)
  wait_until_text_found(title, 5)
  widgets = BROWSER.divs(:id => /^widget-identifier-[0-9]*$/)

  widget_id = nil
  widgets.each do |widget|
    if widget.parent.h2(:text => /#{title}/i).exist?
      widget_id = widget.attribute_value(:id)
      break
    end
  end

  #Try to get the widget from a h3 dossier title
  if !widget_id
    widgets.each do |widget|
      if widget.h3(:class => "dossier", :text => /#{title}/i).exist?
        widget_id = widget.attribute_value(:id)
        break
      end
    end
  end

  #Try to get it from the class
  if !widget_id
    widgets.each do |widget|
      if widget.attribute_value(:class).match(/#{title}$/)
        widget_id = widget.attribute_value(:id)
        break
      end
    end
  end

  widget_id
end

def get_widget_details(title)
  widgets = BROWSER.divs(:id => /^widget-identifier-[0-9]*$/)
  found_widget = nil
  widget_details = {}
  
  widgets.each do |widget|
    if widget.parent.h2(:text => /#{title}/i).exist?
      found_widget = widget
      break
    elsif widget.h3(:class => "dossier", :text => /#{title}/i).exist?
      found_widget = widget
      break
    elsif widget.attribute_value(:class).include? title
      found_widget = widget
      break
    end
  end

  if found_widget
    widget_details['id'] = found_widget.attribute_value(:id)
    begin
      widget_details['class'] = found_widget.attribute_value(:class)
      widget_details['instance_id'] = widget_details['id'].scan(/[0-9]{1,10}/)[0]
    rescue
    end
  end
  
  widget_details
end

# Gently process (make a screenshot, report the error) if an element is not found
def handle_element_not_found(element, name = "")
  take_screenshot()

  unless name.empty?
    feedback = "#{element}: '#{name}' not found on #{BROWSER.url}"
  else
    feedback = "#{element} not found on #{BROWSER.url}"
  end

  if ENV['BREAKPOINT_ON_FAILURE']
    p feedback
    begin
      require 'debugger'; debugger
    rescue Exception => ex
      $log.error "Could not load debugger: #{ex.message}"
    end
  end

  raise feedback
end

# Gently process (make a screenshot, report the error) if an element is found unexpectedly
def handle_element_found(element, name)
  take_screenshot()
  feedback = "#{element}: '#{name}' found on #{BROWSER.url}"
  
  if ENV['BREAKPOINT_ON_FAILURE']
    p feedback
    require 'ruby-debug'
    breakpoint
  end

  raise feedback
end

def update_variable(variable)

  if variable.include?("EPOCH_TIMESTAMP")
    variable = variable.gsub("EPOCH_TIMESTAMP", $CURRENT_EPOCH_TIMESTAMP.to_i.to_s)
  end
  
  if variable.include?("TIMESTAMP")
    variable = variable.gsub("TIMESTAMP", $CURRENT_TIMESTAMP)
  end

  if variable.include?("ENV")
    variable = variable.gsub("ENV", $environment[0..2])
  end

  if variable.include?("LOADTIME")
    begin
      loadtime = "#{(BROWSER.performance.summary[:response_time]/10).to_i/100.0} sec"
    rescue
      starttime = Time.now
      BROWSER.goto BROWSER.url
      loadtime = "#{((Time.now-starttime)*100).to_i/100.0} sec"
    end  
    variable = "#{loadtime + " " * [0, (variable.length-loadtime.length)].max}"
    # Make sure the length is as long as the string
  end
  variable
end

# Closes the browser and creates a new BROWSER instance
def restart_browser()
  $log.debug "Restarting browser in scenario: #{$scenario_name}"
  BROWSER.close
  # Needs to be a global value, else we get a dynamic constant assignment error
  # Most ideal situation is if the BROWSER instance is already a global variable, but ooh well, it works
  $NEW_BROWSER = Watir::Browser.new $WEB_DRIVER, :profile => $profile
  $NEW_BROWSER.goto $SITE
  return $NEW_BROWSER
end

#Functions
def get_instance_id(href)
  return href.scan(/[^\/]*\.html/)[0][0..-6]
end

def get_website_id(href)
  return href.scan(/\?wsite=[^&]*/)[0][7..-1]
end

def get_working_widget(widget_name)
  require 'mechanize'
  require 'yaml'
  require 'uri'
  
  widget_server = CONFIGS['widget-server']
  uri = URI.parse(widget_server)
  base = "#{uri.scheme}://#{uri.host}"
  agent = Mechanize.new
  agent.auth('widgetadmin', 'pr4nc1ngp0ny')
  
  working_widget = {}
  begin
    widget_server_page = agent.get(widget_server)
    widget_instances_page = widget_server_page.link_with(:text => widget_name).click
    widget_instances_list = widget_instances_page.links_with(:text => 'fullpage')
  rescue
    widget_instances_list = []
  end

  widget_instances_list.each do |widget_instance|
    begin
      sleep 5
      widget_id = get_instance_id(widget_instance.href)
      widget_wsite = get_website_id(widget_instance.href)
      widget_preview_page = agent.get(base + widget_instance.href + "&cmsurl='/'")

      if !['200', '301', '302'].include? widget_preview_page.code().to_s
        p "Odd response code: " + widget_preview_page.code().to_s
      else
        working_widget['name'] = widget_name
        working_widget['id'] = widget_id
        working_widget['wsite'] = widget_wsite
        working_widget['preview_page'] = base + widget_instance.href
        break
      end
    rescue Mechanize::ResponseCodeError => ex
      $log.debug "Responsecode error requesting widget:"
      $log.debug ex
    rescue Exception => e
      $log.debug "Ouch, possible connection failure, lets wait for a little while"
      $log.debug e
      sleep 10
    end
  end
  
  if working_widget['id']
    $log.debug "Found widget: #{working_widget['id']}, #{working_widget['wsite']}"
  end
  working_widget
end

#returns widget div or the content area of the page
def get_current_widget()
  if BROWSER.div(:id => $current_widget_id).exist?
    BROWSER.div(:id => $current_widget_id).parent.flash
    return BROWSER.div(:id => $current_widget_id)
  elsif BROWSER.div(:class => "wrapper component").exist?
    BROWSER.div(:class => "wrapper component").flash
    return BROWSER.div(:class => "wrapper component")
  elsif BROWSER.div(:class => "page").exist?
    BROWSER.div(:class => "page").flash
    return BROWSER.div(:class => "page")
  else
    return nil
  end
end

def update_widget_instances(widget_server, env, instances_per_widget=1)
  require 'mechanize'
  require 'yaml'
  require 'uri'
  
  puts "Get widget instances: \n    environment: \t #{env}"

  widgets_to_skip = ["bnl-actueellijst", "bnl-actueeldetail"]
  
  filename = "config/widgets.yml"
  all_widgets = YAML.load_file(filename)
  env_widgets = all_widgets[env]
  
  uri = URI.parse(widget_server)
  base = "#{uri.scheme}://#{uri.host}"
  
  agent = Mechanize.new
  agent.auth('widgetadmin', 'pr4nc1ngp0ny')
  page = agent.get(widget_server)

  # Get all the proper links to the page with the instances from the widget_server page
  widgets = page.links_with(:href => %r{/widgetshop/}i)
  widgets.each do |widget|
    if widget.text.to_s != '0'
      widget_name = widget.text
      
      next if widgets_to_skip.include? widget_name
      
      puts "    Processing widget '#{widget_name}':"
      
      # Check the widgets that are already in the list, remove them if they generate a server error
      if env_widgets[widget_name] and env_widgets[widget_name].length > 0
        # Get all the instances that are in the config file
        env_widgets[widget_name].each do |instance|
          instance_id = instance[1]
          begin
            page = agent.get(widget_server)
            widget_instances_page = page.link_with(:href => widget.href).click
            widget_preview_link = widget_instances_page.link_with(:href => /preview.*\/#{instance_id}.html/).href
            if widget_preview_link
              widget_preview_url = base + widget_preview_link +  "&cmsurl='/'"
            else
              puts "\tRemoving instance id #{instance_id} from configuration file"
              env_widgets[widget_name].delete(instance[0])
              break
            end
            
            widget_preview_page = agent.get(widget_preview_url)
            puts "\tInstance id #{instance_id} from configuration file still works"
          rescue Mechanize::ResponseCodeError => ex
              # remove if it generates a responsecode error
              puts "\tRemoving instance id #{instance_id} from configuration file"
              env_widgets[widget_name].delete(instance[0])
          rescue Exception => e
            p e.message
          end
        end
      else
        puts "\tNo instance in the cofiguration file yet"
        env_widgets[widget_name] = ''
      end
      
      # Try to find more instances if we dont have enough
      if env_widgets[widget_name].length < instances_per_widget
        begin
          page = agent.get(widget_server)
          widget_instances_page = page.link_with(:href => widget.href).click
          widget_instances_list = widget_instances_page.links_with(:href => /preview.*\/[0-9]{1,6}.html/)
        rescue Exception => e
          p e.message
          widget_instances_list = []
        end

        widget_instances_list.each do |widget_instance|
          sleep 1       
          widget_id = get_instance_id(widget_instance.href)
          widget_wsite = get_website_id(widget_instance.href)
          
          if !env_widgets[widget_name][widget_wsite]
            begin
              widget_preview_page = agent.get(base + widget_instance.href + "&cmsurl='/'")
              
              if !['200', '301', '302'].include? widget_preview_page.code().to_s
                puts "\tOdd response code for instance id #{instance_id}. Respcode:" + widget_preview_page.code().to_s
              end

              # Do we have one an instance already of this widget?
              if !env_widgets[widget_name] or env_widgets[widget_name].length == 0
                env_widgets[widget_name] = {widget_wsite => widget_id}
                puts "\tStored instance #{widget_id}, #{widget_wsite}. Respcode: #{widget_preview_page.code().to_s}"
              elsif env_widgets[widget_name].length < instances_per_widget
                env_widgets[widget_name][widget_wsite] = widget_id
                puts "\tStored instance #{widget_id}, #{widget_wsite}. Resp code: #{widget_preview_page.code().to_s}"
              else
                break
              end
            rescue Mechanize::ResponseCodeError => ex
              puts "\tInstance id #{widget_id} fails with respcode: #{ex.response_code}"
            rescue Exception => e
              p e
              puts "\tOuch, possible connection failure, lets wait for a little while"
              sleep 10
            end
          end
        end
      end
    end
  end

  #######################
  # Create yaml file with widget details
  all_widgets = YAML.load_file(filename)
  all_widgets[env] = env_widgets
  p all_widgets.to_yaml
  
  f = File.open(filename, 'w')
  f.write("################################################################################################
# Property of Bibliotheek.nl. Author: Mark Barzilay. For info and questions: barzilay@spritecloud.com
#
# Config file for the test automation
# This one is updated from svn. You can create your own config file by
# When a config_local.yml exists, that will then be loaded instead of this default config file

")
  
  f.write(all_widgets.to_yaml)
  f.close

  p "Widget details stored in yaml file: #{filename}"
end

def get_har_data(url=BROWSER.url)
  require 'browsermob-proxy'
  
  server = BrowserMob::Proxy::Server.new("d:/svn_archive_service/production/bnl/bibliotheek_nl/trunk/features/support/browsermob-proxy-2.0-beta-4/bin/browsermob-proxy.bat")
  server.start

  proxy = server.create_proxy
  proxy.new_har("latest_har")
  BROWSER.goto url
  har_data = proxy.har
  proxy.close
  
  return har_data
end

# Method is the one making the actual HTTP request
def get_xml_data(url)
  require 'net/http'
  require 'xmlsimple'
  
  uri = URI(url)
  response = Net::HTTP.get(uri)
  data = XmlSimple.xml_in(response)
end

def get_software_version_info()

  version_info = {'Website' => '?'}
end

def get_title(title)
  BROWSER.element(:text => /#{title}/).wait_until_present(10) rescue found_title = nil
  
  begin
    found_title = BROWSER.h2(:text => /#{title}/i) unless !BROWSER.h2(:text => /#{title}/i).present?
  rescue Exception => e
    $log.debug e.message
    found_title = nil
  end
  
  if !found_title and BROWSER.h3(:class => "dossier", :text => /#{title}/i).exist?
    begin
      found_title = BROWSER.h3(:class => "dossier", :text => /#{title}/i) unless !BROWSER.h3(:class => "dossier", :text => /#{title}/i).present?
    rescue Exception => e
      $log.debug e.message
    end
  end
  
  if !found_title and BROWSER.h1(:text => /#{title}/i).exist?
    begin
      found_title = BROWSER.h1(:text => /#{title}/i) unless !BROWSER.h1(:text => /#{title}/i).present?
    rescue Exception => e
      $log.debug e.message
    end
  end
  
   if !found_title and BROWSER.h3(:text => /#{title}/i).exist?
    begin
      found_title = BROWSER.h3(:text => /#{title}/i) unless !BROWSER.h3(:text => /#{title}/i).present?
    rescue Exception => e
      $log.debug e.message
    end
  end
  
  found_title
end

def find_input_field(field_label, textarea_type = false)

    unless textarea_type
        text_field = BROWSER.text_fields(:name => field_label).select{|field| field.present?}[0]
        return  text_field unless text_field.nil?
        text_field = BROWSER.text_fields(:name => /#{field_label}/).select{|field| field.present?}[0]
        return  text_field unless text_field.nil?
    else
        text_field = BROWSER.textareas(:name => field_label).select{|field| field.present?}[0]
        return  text_field unless text_field.nil?
        text_field = BROWSER.textareas(:name => /#{field_label}/).select{|field| field.present?}[0]
        return  text_field unless text_field.nil?
    end
  
    #if it is a search query, try to find it by using an input field with value 'query'
    if ['vind', 'search', 'zoeken'].include? field_label
        text_fields = BROWSER.text_fields(:name => /q/)
        text_fields.each do |text_field|
            return text_field unless !text_field.visible?
        end

        text_fields = BROWSER.text_fields(:name => "keyword")
        text_fields.each do |text_field|
            return text_field unless !text_field.visible?
        end
    end
    return nil
end

def find_link(text, array_item = 0)
  wait_until_text_found(text, 5)
  link = BROWSER.as(:text => text).select{|field| field.present?}[array_item]
  return link unless link.nil?
  link = BROWSER.as(:href => /#{text}/).select{|field| field.present?}[array_item]
  return link unless link.nil?
  #return BROWSER.a(:text => text) if BROWSER.a(:text => text) and BROWSER.a(:text => text).visible? rescue ""
  #return BROWSER.a(:href => /#{text}/) if BROWSER.a(:href => /#{text}/) and BROWSER.a(:href => /#{text}/).visible? rescue ""
  
  links = BROWSER.as(:text => text)
  links.each do |link|
    if link.visible?
      return link
    end
  end
  
  #try to find it case insensitive
  links = BROWSER.as(:text => /#{text}/i)
  links.each do |link|
    if link.visible?
      $log.debug "Found '#{link.text}' by case insensitive regular expression '#{text}'"
      return link
    end
  end
  
  return nil
end

def get_loadtime(url)
  starttime = Time.now
  BROWSER.goto url
  endtime = Time.now-starttime
end

def find_select_list(label)
  return BROWSER.select_list(:id => label) if BROWSER.select_list(:id => label).exist?
  raise handle_element_not_found("select_list", label)
end

def find_checkbox(text)
  return BROWSER.input(:type => "radio", :value => /#{text}/i).parent if BROWSER.input(:type => "radio", :value => /#{text}/i).exists?
  return nil
end

# Utitlity function for getting optional element.
def get_optional_element(*args)
  elem = nil
  begin
    elem = BROWSER.elements(*args)
  rescue Exception => e
    pp "Error", e
  end

  return elem
end

# Utility function for selecting a random (non-selected, and enabled) option
# from a list.
def select_random_different_option(options)
  if options.length <= 1
    return # nothing to do
  end

  # Pick randomg index that is not currently selected or disabled
  idx = rand(options.length).to_i
  while options[idx].disabled? or options[idx].selected?
    idx = rand(options.length).to_i
  end

  # Select this option
  options[idx].select
end

# Utility function for changing item properties in the basket
def randomly_change_item_property(*args)
  # Iff we find a matching element, try to randomly select a (different)
  # option. Otherwise, treat the step as successful.
  parent = get_optional_element(*args)
  if not parent
    return
  end

  # Select a random (different) option
  parent.each do |elem|
    select_random_different_option(elem.select_list.options)
    break # only the first
  end
end
