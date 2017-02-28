# Lapis Lazuli

LapisLazuli provides cucumber helper functions and scaffolding for easier (web)
test automation suite development.

[![Gem Version](https://badge.fury.io/rb/lapis_lazuli.svg)](http://badge.fury.io/rb/lapis_lazuli)
[![Code Climate](https://codeclimate.com/github/spriteCloud/lapis-lazuli/badges/gpa.svg)](https://codeclimate.com/github/spriteCloud/lapis-lazuli)
[![Test Coverage](https://codeclimate.com/github/spriteCloud/lapis-lazuli/badges/coverage.svg)](https://codeclimate.com/github/spriteCloud/lapis-lazuli)

A lot of functionality is aimed at dealing better with [Watir](http://watir.com/),
such as:

- Easier/more reliable find and wait functionality for detecting web page elements.
- Easier browser handling
- Better error handling
- etc.

## Installation

For detailed installation notes, go to: http://www.testautomation.info/Installing_ruby_with_cucumber

Add this line to your application's Gemfile:

```ruby
gem 'lapis_lazuli'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install lapis_lazuli
```

## Usage

The Lapis Lazuli project has two main purposes:

- Provide a repository of common test functions for test automation engineers.
- Make it easy to get started on a test automation project with these test
  functions.

The first goal is fulfilled by the Lapis Lazuli module itself, which can be
imported in any cucumber project like this:

```ruby
require 'lapis_lazuli'
World(LapisLazuli)
```

All of Lapis Lazuli's helper functions will be available in your step definitions
then. However, you won't need to do this if you create a new Lapis Lazuli project.
Simple run:

```bash
$ lapis_lazuli create <projectpath>
```

And a cucumber project will be set up for you in the given path. The last path
name component will be considered the project name, so e.g. a path of
`projects/for_client/website1` will mean the project's name is going to be
`website1`.

Change to that newly created project directory and read the README.md file there
for further instructions.

Be sure to read [the GitHub Wiki](https://github.com/spriteCloud/lapis-lazuli/wiki) or [testautomation.info](http://www.testautomation.info/) for
further documentation.

## Contributing

Please see [the Wiki page on contributing](https://github.com/spriteCloud/lapis-lazuli/wiki/Contributing)

## License
Copyright (c) 2013-2017 spriteCloud B.V. and other node-apinator contributors. See [the LICENSE file](LICENSE) for details.
