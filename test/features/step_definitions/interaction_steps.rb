################################################################################
# Copyright 2014 spriteCloud B.V. All rights reserved.
# Generated by LapisLazuli, version 0.0.1
# Author: "spriteCloud" <info@spritecloud.com>

require 'test/unit/assertions'

include Test::Unit::Assertions

Given(/^I navigate to the (.*) test page$/) do |page|
  config = "server.url"
  if has_env?(config)
    url = env(config)
    driver.goto "#{url}#{page.downcase.gsub(" ","_")}.html"
  else
    error(:env => config)
  end
end

Given(/I click (the|a) (first|last|random|[0-9]+[a-z]+) (.*)$/) do |arg1, index, type|
  # Convert the type text to a symbol
  type = type.downcase.gsub(" ","_")

  pick = 0
  if ["first","last","random"].include?(index)
    pick = index.to_sym
  else
    pick = index.to_i - 1
  end
  # Options for find
  options = {}
  # Select the correct element
  options[type.to_sym] = {}
  # Pick the correct one
  options[:pick] = pick
  # Execute the find
  type_element = driver.find(options)
  type_element.click
end


Given(/^I create a firefox browser named "(.*?)"( with proxy to "(.*?)")$/) do |name, proxy, proxy_url|
  b = nil
  if proxy
    log.debug("Starting with proxy")
    b = driver.create :firefox, :proxy_url => proxy_url
  else
    b = driver.create :firefox
  end
  scenario.storage.set(name, b)
end

Given(/^I close the browser named "(.*?)"$/) do |name|
  if scenario.storage.has? name
    b = scenario.storage.get name
    b.close
  else
    error("No item in the storage named #{name}")
  end
end

When(/^I find "(.*?)" and name it "(.*?)"$/) do |id, name|
  element = driver.find(id)
  scenario.storage.set(name, element)
end

xpath_fragment = nil
Given(/^I specify a needle "(.+?)" and a node "(.+?)" (and an empty separator )?to xp_contains$/) do |needle, node, empty_sep|
  if empty_sep.nil?
    xpath_fragment = xp_contains(node, needle)
  else
    xpath_fragment = xp_contains(node, needle, '')
  end
end

Then(/^I expect an xpath fragment "(.*?)"$/) do |fragment|
  assert fragment == xpath_fragment, "Fragment was not as expected: got '#{xpath_fragment}' vs expected '#{fragment}'."
end

Then(/^I expect the fragment "(.*?)" to find (\d+) element\(s\)\.$/) do |fragment, n|
  elems = driver.elements(:xpath => "//div[#{fragment}]")
  assert n.to_i == elems.length, "Mismatched amount: got #{elems.length} vs. expected #{n}"
end

elems = []
Given(/^I search for elements where node "(.+?)" contains "(.+?)" and not "(.+?)"$/) do |node, first, second|
  clause = xp_and(xp_contains(node, first), xp_not(xp_contains(node, second)))
  elems = driver.elements(:xpath => "//div[#{clause}]")
end

Then(/^I expect to find (\d+) elements\.$/) do |n|
  assert n.to_i == elems.length, "Mismatched amount: got #{elems.length} vs. expected #{n}"
end

When(/^I go to "(.*?)"$/) do |url|
  driver.goto url
end

Then(/^I should be able to click the first button by event$/) do
  elem = driver.button(:id => 'first')
  driver.on_click(elem)
  driver.wait(
    :timeout => 1,
    :text => 'first clicked',
    :groups => ['wait'],
  )
end

Then(/^I should be able to click the first button by using JavaScript$/) do
  elem = driver.button(:id => 'first')
  driver.js_click(elem)
  driver.wait(
    :timeout => 1,
    :text => 'first clicked',
    :groups => ['wait'],
  )
end

Then(/^I should be able to click the first button by click type (.*?)$/) do |type|
  elem = driver.button(:id => 'first')
  driver.click_type(elem, type)
  driver.wait(
    :timeout => 1,
    :text => 'first clicked',
    :groups => ['wait'],
  )
end


Then(/^I should be able to click the first button by force click$/) do
  elem = driver.button(:id => 'first')
  driver.force_click(elem)
  driver.wait(
    :timeout => 1,
    :text => 'first clicked',
    :groups => ['wait'],
  )
end

Given(/^I set environment variable "(.*?)" to "(.*?)"$/) do |var, val|
  ENV[var]=val
end

Given(/^I annotate a step with (.*?)$/) do |data|
  annotate data
end

Then(/^the report should include (.*?) and (.*?) in the correct place$/) do |data1, data2|
  # Our test completely ignores the "scope" part, because the scope is the
  # scenario/example anyway. Instead we just check the stored values are
  # as expected.
  annotations.each do |scope, values|
    assert ([[data1], [data2]] == values), "Stored values: #{values}, expected [[#{data1}], [#{data2}]]"
  end
end
