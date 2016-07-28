#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2016 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
module Drivers
  class Appium
    MATCHES = [
      :appium,
      :ios,
      :iphone,
      :ipad,
      :android
    ].freeze

    class << self
      def match(wanted)
        # In case wanted is a string, force to symbol
        return MATCHES.include?(wanted.downcase.to_sym)
      end

      def precondition_check(wanted, data = nil)
        # Run-time dependency.
        begin
          require 'appium_lib'
        rescue LoadError => err
          raise LoadError, "#{err}: you need to add 'appium_lib' to your Gemfile before using the driver."
        end
      end

      def create(world, wanted, data = nil)
        instance = ::Appium::Driver.new(data).start_driver
        return wanted, instance
      end
    end # class << self

  end # class Appium
end # module Drivers
end # module LapisLazuli
