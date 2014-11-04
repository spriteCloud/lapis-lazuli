# Lapis Lazuli

Cucumber helper functions and scaffolding for spriteCloud TA engineers.

## Installation

Add this line to your application's Gemfile:

    gem 'lapis_lazuli'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lapis_lazuli

## Usage

The Lapis Lazuli project has two main purposes:

- Provide a repository of common test functions for spriteCloud TA engineers.
- Make it easy to get started on a test automation project with these test
  functions.

The first goal is fulfilled by the Lapis Lazuli module itself, which can be
imported in any cucumber project like this:

    require 'lapis_lazuli'
    include LapisLazuli

All of Lapis Lazuli's helper functions will be available in your step definitions
then. However, you won't need to do this if you create a new Lapis Lazuli project.
Simple run:

    $ lapis_lazuli create <projectpath>

And a cucumber project will be set up for you in the given path. The last path
name component will be considered the project name, so e.g. a path of
`projects/for_client/website1` will mean the project's name is going to be
`website1`.

Change to that newly created project directory and read the README.md file there
for further instructions.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

When you are contributing, it makes sense to not use the github version of
Lapis Lazuli, but your local changes instead. This is fine when running
`lapis_lazuli`, as you just need to type a different path in the shell.

But `bundle install` in a newly created Lapis Lazuli project may cause some
problems. You can force bundler to use your locally checked out Lapis Lazuli
instead of the github version by running:

    $ bundle config local.lapis_lazuli /path/to/local/lapis_lazuli

