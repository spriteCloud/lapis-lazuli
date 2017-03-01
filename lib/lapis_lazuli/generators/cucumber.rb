#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require 'lapis_lazuli/version'

require 'thor/group'

module LapisLazuli
  module Generators

    PROJECT_PATHS = [
      'config',
      'features',
      File.join('features', 'step_definitions'),
      File.join('features', 'support'),
      'logs',
      'results',
      'screenshots',
    ]


    ALLOWED_HIDDEN = [
      '.gitignore'
    ]



    class Cucumber < Thor::Group
      include Thor::Actions

      argument :path, :type => :string

      # Bug in Thor: this seems to need to be in place both here, and in the CLI
      # class - here to actually work, and in the CLI class to be shown in the help.
      class_option :branch, :aliases => "-b", :type => :string, :default => nil



      def create_directory_structure
        empty_directory(path)
        PROJECT_PATHS.each do |p|
          empty_directory(File.join(path, p))
        end
      end



      def copy_template
        opts = {
          :year => Time.now.year,
          :user => Cucumber.get_username(self),
          :email => Cucumber.get_email(self),
          :lapis_lazuli => {
            :version => LapisLazuli::VERSION,
            :dependency => '"' + LapisLazuli::VERSION + '"',
          },
          :project => {
            :name => File.basename(path),
          },
        }

        # If a branch was specified on the CLI, we have to update the dependency
        # string.
        if options.has_key?("branch")
          opts[:lapis_lazuli][:dependency] = ":github => 'spriteCloud/lapis-lazuli', :branch => '#{options["branch"]}'"
        end

        require 'facets/string/lchomp'
        require 'find'
        Find.find(Cucumber.source_root) do |name|
          # Skip the source root itself
          next if name == Cucumber.source_root

          # Find the relative path and file name component
          relative = name.lchomp(Cucumber.source_root + File::SEPARATOR)
          filename = File.basename(relative)

          # Ignore hidden files UNLESS they're listed in the allowed hidden
          # files.
          if filename.start_with?('.')
            next if not ALLOWED_HIDDEN.include?(filename)
          end

          # Create directories as empty directories, and treat every file as 
          # a template.
          if File.directory?(name)
            empty_directory(File.join(path, relative))
          else
            template(relative, File.join(path, relative), opts)
          end
        end
      end



      def self.source_root
        File.join(File.dirname(__FILE__), "cucumber", "template")
      end



      def self.run_helper(cuke, command, default)
        begin
          cuke.run(command, {:capture => true}).strip || default
        rescue
          default
        end
      end



      def self.get_username(cuke)
        run_helper(cuke, 'git config --get user.name', 'spriteCloud B.V.')
      end



      def self.get_email(cuke)
        run_helper(cuke, 'git config --get user.email', 'info@spritecloud.com')
      end
    end
  end
end
