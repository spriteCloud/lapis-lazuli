# Lapis Lazuli

Cucumber helper functions and scaffolding for easier test automation suite development.

## Installation

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

- Provide a repository of common test functions for spriteCloud TA engineers.
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

Be sure to read [the Wiki](https://github.com/spriteCloud/lapis-lazuli/wiki) for
further documentation.

## Contributing

Please see [the Wiki page on contributing](https://github.com/spriteCloud/lapis-lazuli/wiki/Contributing)

## License
Copyright (c) 2013-2015 spriteCloud B.V. and other node-apinator contributors. See [the LICENSE file](LICENSE) for details.
