# Lapis Lazuli Test Suite

This cucumber project contains a web server with simple test cases to validate Lapis Lazuli behavior.

Author: "Onno Steenbergen" <info@spritecloud.com>

# Setup

## General

- Make sure you have ruby 2.1 or later installed.
- Make sure you have firefox and/or chrome installed
- Install the bundler gem:

    $ gem install bundler

- Install all of the required gems defined in the gemfile:

    $ bundle install

- Run cucumber through bundler:

    $ bundle exec cucumber

# Code Coverage

Code coverage can be enabled if the `simplecov` gem is installed, by specifying
the `COVERAGE` environment variable when running the test suite:

    $ COVERAGE=1 bundle exec cucumber

# Contributing

If you create new utility functions and want to contribute them to the Lapis
Lazuli project, see https://github.com/spriteCloud/lapis-lazuli
