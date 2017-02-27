#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'lapis_lazuli/assertions'
require 'lapis_lazuli/argparse'

module LapisLazuli
module BrowserModule

  ##
  # Module with helper functions to do with DOM element interaction
  module Interaction
    include LapisLazuli::Assertions
    include LapisLazuli::ArgParse

    ##
    # Click types
    DEFAULT_CLICK_TYPES = [ :method, :event, :js ]

    ##
    # Given an element, fires a click event on it.
    def on_click(elem)
      elem.fire_event('onClick')
    end


    ##
    # Given an element, uses JavaScript to click it.
    def js_click(elem)
      self.execute_script('arguments[0].click();', elem)
    end


    ##
    # Combination of elem.click, on_click and js_click: uses the click method
    # given as the second parameter; may be one of :method, :event, :js.
    def click_type(elem, type)
      type = type.to_sym
      assert DEFAULT_CLICK_TYPES.include?(type), "Not a valid click type: #{type}"

      case type
      when :method
        elem.click
      when :event
        on_click(elem)
      when :js
        js_click(elem)
      end
    end


    ##
    # Forces clicking by trying any of the given types of click on the given
    # element, until one succeeds. If all fail, the corresponding errors are
    # raised as an Array
    def click_types(elem, types = DEFAULT_CLICK_TYPES)
      errors = []
      types.each do |type|
        begin
          click_type(elem, type)
        rescue RuntimeError => err
          errors << err
        end
      end

      if errors.length > 0
        world.error("Could not click #{elem} given any of these click types: #{types}: #{errors}")
      end
    end


    ##
    # Tries the default click types on all elements passed to it.
    def force_click(*args)
      elems = make_list_from_nested(args)

      elems.each do |elem|
        click_types(elem, DEFAULT_CLICK_TYPES)
      end
    end


  end # module Interaction
end # module BrowserModule
end # module LapisLazuli
