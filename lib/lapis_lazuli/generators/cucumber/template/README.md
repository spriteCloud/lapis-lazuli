# Tests for <%= config[:project][:name] %>

Author: "<%= config[:user] %>" <<%= config[:email] %>>

# Setup

See: www.testautomation.info/index.php?title=Installing_ruby_with_cucumber

## General

- Make sure you have ruby 2.0 or later installed.
- Make sure you have firefox and/or chrome installed
- Download chromedriver and put it into your ./ruby/bin folder
- Download geckodriver and put it into your ./ruby/bin folder
- Install the bundler gem:

    $ gem install bundler

- Install all of the required gems defined in the gemfile:

    $ bundle install

- Run cucumber through bundler:

    $ bundle exec cucumber

# Contributing

If you create new utility functions and want to contribute them to the Lapis
Lazuli project, see https://github.com/spriteCloud/lapis-lazuli
