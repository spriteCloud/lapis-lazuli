require 'thor'

require 'spritecuke/generators/cucumber'

module Spritecuke
  class CLI < Thor

    desc "create", "Creates a cucumber project with some common step definitions."
    def create(path, name)
      Spritecuke::Generators::Cucumber.start([path, name])
    end
  end
end
