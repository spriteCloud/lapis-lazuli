#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "securerandom"

require "lapis_lazuli/scenario"

require "lapis_lazuli/world/config"

module LapisLazuli
module WorldModule
  ##
  # Module for variable replacement
  #
  # Manages the following:
  #   @scenario   - for per-scenario variables
  #   @uuid       - for the entire test run
  #   @time       - for the entire test run
  #   @storage    - for the entire test run
  module Variable
    include LapisLazuli::WorldModule::Config

    ##
    # Scenario "singleton"
    def scenario
      if @scenario.nil?
        @scenario = Scenario.new
      end
      return @scenario
    end

    ##
    # Time "singleton"
    def time
      if @time.nil?
        time = Time.now
        @time = {
          :timestamp => time.strftime('%y%m%d_%H%M%S'),
          :epoch => time.to_i.to_s
        }
      end
      return @time
    end

    ##
    # UUID "singleton"
    def uuid
      if @uuid.nil?
        @uuid = SecureRandom.hex
      end
      return @uuid
    end

    ##
    # Storage "singleton"
    def has_storage?
      return !@storage.nil?
    end

    def storage
      if @storage.nil?
        @storage = Storage.new
        @storage.set("time", time)
        @storage.set("uuid", uuid)

        # Register a finalizer, so we can clean up the proxy again
        ObjectSpace.define_finalizer(self, Variable.destroy(self))
      end
      return @storage
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
      string % {
        :epoch => time[:epoch],
        :timestamp => time[:timestamp],
        :uuid => uuid,
        :email => "test_#{uuid}@#{email_domain}",
        :scenario_id => scenario.id,
        :scenario_epoch => scenario.time[:epoch],
        :scenario_timestamp => scenario.time[:timestamp],
        :scenario_email => "test_#{uuid}_scenario_#{scenario.uuid}@#{email_domain}",
        :scenario_uuid => scenario.uuid,
        :random => rand(9999),
        :random_small => rand(99),
        :random_lange => rand(999999),
        :random_uuid => random_uuid,
        :random_email => "test_#{uuid}_random_#{random_uuid}@#{email_domain}"
      }
    end

    ##
    # Same as variable, but modify the string.
    def variable!(string)
      string.replace(variable(string))
    end


  private

    def self.destroy(world)
      Proc.new do
        # Destroy storage
        if world.has_storage?
          world.storage.destroy(world)
        end
      end
    end



  end # module Variable
end # module WorldModule
end # module LapisLazuli
