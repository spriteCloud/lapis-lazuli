#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2016 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#


module LapisLazuli
module Drivers
  class Watir
    MATCHES = [
      :chrome,
      :safari,
      :ie,
      :firefox
    ].freeze

    class << self
      def match(wanted)
        # In case wanted is a string, force to symbol
        return MATCHES.include?(wanted.downcase.to_sym)
      end

      def precondition_check(wanted, data = nil)
        # Run-time dependency.
        begin
          require 'selenium-webdriver'
          require 'watir-webdriver'
          require "watir-webdriver/extensions/alerts"
        rescue LoadError => err
          raise LoadError, "#{err}: you need to add 'watir-webdriver', 'watir-webdriver-performance' and 'watir-scroll' to your Gemfile before using the driver."
        end

        # Select the correct driver
        wanted = wanted.downcase.to_sym
        case wanted
        when :ie
          require 'rbconfig'
          if not (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
            world.error("You can't run IE tests on non-Windows machine")
          end
        when :ios
          if not RUBY_PLATFORM.downcase.include?("darwin")
            world.error("You can't run IOS tests on non-mac machine")
          end
        end
      end

      def create(world, wanted, data = nil)
        @@world = world

        # Filter out keywords we know.
        proxy_url = nil
        if not data.nil? and not data.empty?
          proxy_url = data[:proxy_url]
          data.delete(:proxy_url)
        end

        # Assemble arguments
        wanted = wanted.downcase.to_sym
        config = create_config(data)

        args = [wanted]
        if not config.nil? and not config.empty?
          args.push(config)
        end

        # Proxy support
        if not proxy_url.nil? or @@world.has_proxy?
          assert wanted == :firefox, "Proxies not supported for driver '#{wanted}'!"

          if proxy_url.nil?
            if not @@world.proxy.has_session?
              @@world.proxy.create
            end

            proxy_url = "#{@@world.proxy.ip}:#{@@world.proxy.port}"
          end

          profile = create_profile_with_proxy(proxy_url)
          args.push({:profile => profile})
        end

        # Create driver instance
        instance = nil
        begin
          instance = ::Watir::Browser.new(*args)
        rescue ::Selenium::WebDriver::Error::UnknownError => err
          @@world.error(exception: err, message: "Unknown error occurred when creating Watir driver!")
        end

        return wanted, instance
      end

      def create_config(data)
        data # default is to do nothing
      end

      def create_profile_with_proxy(url)
        @@world.log.debug("Configuring Firefox proxy: #{url}")
        profile = ::Selenium::WebDriver::Firefox::Profile.new
        profile.proxy = ::Selenium::WebDriver::Proxy.new http: url, ssl: url
        profile
      end
    end # class << self
  end # class Watir
end # module Drivers
end # module LapisLazuli
