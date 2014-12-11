#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
  ##
  # Module for variable replacement (part of World)
  #
  # Uses the following managed by World:
  #   @time
  #   @scenario
  #   @uuid
  module Variable
    ##
    # Update the variable with timestamps
    def variable(string)
      email_domain = "spriteymail.net"
      if self.has_env_or_config?("email_domain")
        email_domain = self.env_or_config("email_domain")
      end
      random_uuid = SecureRandom.hex
      string % {
        :epoch => @time[:epoch],
        :timestamp => @time[:timestamp],
        :uuid => @uuid,
        :email => "test_#{@uuid}@#{email_domain}",
        :scenario_id => @scenario.id,
        :scenario_epoch => @scenario.time[:epoch],
        :scenario_timestamp => @scenario.time[:timestamp],
        :scenario_email => "test_#{@uuid}_scenario_#{@scenario.uuid}@#{email_domain}",
        :scenario_uuid => @scenario.uuid,
        :random => rand(9999),
        :random_small => rand(99),
        :random_lange => rand(999999),
        :random_uuid => random_uuid,
        :random_email => "test_#{@uuid}_random_#{random_uuid}@#{email_domain}"
      }
    end

    ##
    # Same as variable, but modify the string.
    def variable!(string)
      string.replace(self.variable(string))
    end


  end # module Variable
end # module LapisLazuli
