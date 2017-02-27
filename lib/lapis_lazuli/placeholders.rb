#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
#
module LapisLazuli
  ##
  # Placeholders and their meanings.
  # The first value is a string to be eval'd to determine the value the
  # placeholder is to be replaced with.
  # The second value describes the meaning.
  PLACEHOLDERS = {
    :timestamp => ['time[:timestamp]', 'The local time at which the test run started.'],
    :iso_timestamp => ['time[:iso_timestamp]', 'The UTC time at which the test run started.'],
    :iso_short => ['time[:iso_short]', 'A shorter version of the UTC time above.'],
    :epoch => ['time[:epoch]', 'An integer representation of the local time above, relative to the epoch.'],
    :email => ['"test_#{uuid}@#{email_domain}"', 'A unique email for the test run (contains the UUID).'],
    :uuid => ['uuid', 'A UUID for the test run.'],
    :scenario_id => ['scenario.id', 'A unique identifier for the current scenario based on the title, in filesystem safe form.'],
    :scenario_timestamp => ['scenario.time[:timestamp]', 'Same as timestamp, but relative to the start of the scenario.'],
    :scenario_iso_timestamp => ['scenario.time[:iso_timestamp]', 'Same as iso_timestamp, but relative to the start of the scenario.'],
    :scenario_iso_short => ['scenario.time[:iso_short]', 'Same as iso_short, but relative to the start of the scenario.'],
    :scenario_epoch => ['scenario.time[:epoch]', 'Same as epoch, but relative to the start of the scenario.'],
    :scenario_email => ['"test_#{uuid}_scenario_#{scenario.uuid}@#{email_domain}"', 'Same as email, but contains the test run UUID and the scenario UUID.'],
    :scenario_uuid => ['scenario.uuid', 'A UUID for the scenario.'],
    :random => ['rand(9999)', 'A random integer <10,000.'],
    :random_small => ['rand(99)', 'A random integer <100.'],
    :random_lange => ['rand(999999)', 'A random integer <1,000,000.'],
    :random_uuid => ['random_uuid', 'A random UUID.'],
    :random_email => ['"test_#{uuid}_random_#{random_uuid}@#{email_domain}"', 'Same as email, but contains the test run and the random UUID.'],
    :versions => ['LapisLazuli.software_versions.nil? ? "" : JSON.generate(LapisLazuli.software_versions)', 'A JSON serialized string of software versions found in e.g. the AfterConfiguration hook.']
  }
end # module LapisLazuli
