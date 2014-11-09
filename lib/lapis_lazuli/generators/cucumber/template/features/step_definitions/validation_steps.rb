################################################################################
# Copyright <%= config[:year] %> spriteCloud B.V. All rights reserved.
# Generated by LapisLazuli, version <%= config[:lapis_lazuli][:version] %>
# Author: "<%= config[:user] %>" <<%= config[:email] %>>

require 'lapis_lazuli'
ll = LapisLazuli::LapisLazuli.instance

Then(/I see "([^"]*)" on the page/) do |string|
	ll.browser.wait(:text => /#{string}/i)
end