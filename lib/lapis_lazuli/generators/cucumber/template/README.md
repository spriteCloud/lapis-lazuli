# Tests for <%= config[:project][:name] %>

Author: "<%= config[:user] %>" <<%= config[:email] %>>

# Setup

## General

- Make sure you have ruby 1.9 or later installed.
- Make sure you have firefox and/or chrome installed
- Install the bundler gem:

    $ gem install bundler

- Install all of the required gems defined in the gemfile:

    $ bundle install

- Run cucumber or regressinator through bundler:

    $ bundle exec cucumber
    $ bundle exec regressinator legacy cucumber

# Contributing

If you create new utility functions and want to contribute them to the Lapis
Lazuli project, see https://github.com/spriteCloud/lapis-lazuli
