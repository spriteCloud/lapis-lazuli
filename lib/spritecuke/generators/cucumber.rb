require 'thor/group'

module Spritecuke
  module Generators
    class Cucumber < Thor::Group
      include Thor::Actions

      argument :path, :type => :string
      argument :name, :type => :string
    end
  end

  def create_group
    empty_directory(path)
  end

  def copy_cucumber
    template("foo.txt", "#{path}/#{name}.txt")
  end
end
