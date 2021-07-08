#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "securerandom"
require 'json'

require "lapis_lazuli/scenario"
require "lapis_lazuli/versions"
require "lapis_lazuli/runtime"
require "lapis_lazuli/placeholders"

require "lapis_lazuli/world/config"

module LapisLazuli
module WorldModule
  ##
  # Module for variable replacement
  #
  # Manages the following:
  #   scenario   - for per-scenario variables
  #   uuid       - for the entire test run
  #   time       - for the entire test run
  #   storage    - for the entire test run
  #   versions   - versions as gathered by e.g. fetch_versions
  module Variable
    include LapisLazuli::WorldModule::Config

    ##
    # Scenario "singleton"
    def scenario
      return data(:scenario) do
        Scenario.new
      end
    end

    ##
    # Time "singleton"
    def time
      return data(:time) do
        time = Time.now
        @time = {
          :timestamp => time.strftime('%y%m%d_%H%M%S'),
          :iso_timestamp => time.utc.strftime("%FT%TZ"),
          :iso_short => time.utc.strftime("%y%m%dT%H%M%SZ"),
          :epoch => time.to_i.to_s
        }
      end
    end

    ##
    # UUID "singleton"
    def uuid
      return data(:uuid) do
        SecureRandom.hex
      end
    end

    ##
    # Storage "singleton"
    def has_storage?
      b = Runtime.instance.get :variable_data
      return !b[:storage].nil?
    end

    def storage
      return data(:storage) do
        storage = Storage.new
        storage.set("time", time)
        storage.set("uuid", uuid)

        storage
      end
    end


    ##
    # Update the variable with timestamps
    def variable(string)
      init

      email_domain = "spriteymail.net"
      if has_env_or_config?("email_domain")
        email_domain = env_or_config("email_domain")
      end
      random_uuid = SecureRandom.hex

      # Prepare current values.
      values = {}
      LapisLazuli::PLACEHOLDERS.each do |placeholder, value|
        values[placeholder] = eval value[0]
      end

      return string % values
    end

    ##
    # Same as variable, but modify the string.
    def variable!(string)
      string.replace(variable(string))
    end

  private

    def data(name, &block)
      d = Runtime.instance.get :variable_data
      if not d.nil?
        if not d.is_a? Hash
          raise "Expect a hash for variables managed by the Variable module"
        end
      else
        d = {}
      end

      if not d.has_key? name
        value = block.call()
        d[name] = value

        Runtime.instance.set(self, :variable_data, d, Variable.destroy(self))
      end

      return d[name]
    end


    def self.destroy(world)
      Proc.new do |w|
        if world.has_storage?
          world.storage.destroy(world)
        end
      end
    end
  end # module Variable
end # module WorldModule
end # module LapisLazuli
