#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2015 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

# Hack for cucumber 2.0.x
begin
  module Cucumber
    module Core
      module Ast
        class ExamplesTable
          public :example_rows
        end # ExamplesTable
      end # Ast
    end # Core
  end # Cucumber
rescue NameError
  # Not cucumber 2.0.x
end


module LapisLazuli
  ##
  # Convenience module for dealing with aspects of the cucumber AST. From
  # version 1.3.x to version 2.0.x, some changes were introduced here.
  module Ast
    ##
    # Return a unique and human parsable ID for scenarios
    def scenario_id(scenario)
      # For 2.0.x, the best scenario ID is one prefixed by the file name + line
      # number, followed by the feature name, scenario name, and table data (if
      # applicable).
      if is_cucumber_2?(scenario)
        id = [scenario.location.to_s]
        for i in 0 .. scenario.source.length - 1 do
          part = scenario.source[i]
          if part.respond_to?(:name)
            id << part.name
          elsif part.is_a?(Cucumber::Core::Ast::ExamplesTable::Row)
            id << part.values.join("|")
          end
        end
        return id
      end

      case scenario
      when Cucumber::Ast::Scenario
        return [
          scenario.feature.file,
          scenario.name
        ]
      when Cucumber::Ast::OutlineTable::ExampleRow
        return [
          scenario.scenario_outline.feature.file,
          scenario.scenario_outline.name,
          scenario.name
        ]
      end
    end


    ##
    # Tests whether the given scenario object indicates we're using cucumber 2.x
    def is_cucumber_2?(scenario)
      begin
        # The assumption - FIXME perhaps wrong - is that cucumber 1.3.x does not
        # have this source array.
        return (scenario.respond_to?(:source) and scenario.source.is_a?(Array))
      rescue
        return false
      end
    end


    ##
    # Tests whether the scenario object is a single scenario
    def is_scenario?(scenario)
      begin
        # 1.3.x
        return scenario.class == Cucumber::Ast::Scenario
      rescue
        # 2.0.x - everything is a Cucumber::Core::Test::Case
        return (not scenario.outline?)
      end
    end


    ##
    # Tests whether the scenario object is a table row
    def is_table_row?(scenario)
      begin
        # 1.3.x
        return scenario.class == Cucumber::Ast::OutlineTable::ExampleRow
      rescue
        # 2.0.x - everything is a Cucumber::Core::Test::Case
        return scenario.outline?
      end
    end


    ##
    # Tests whether this scenario is the last scenario of a feature
    def is_last_scenario?(scenario)
      if is_scenario?(scenario)
        begin
          # 2.0.x
          return (scenario.feature.feature_elements.last.location == scenario.location)
        rescue
          # 1.3.x
          return (scenario.feature.feature_elements.last == scenario)
        end

      elsif is_table_row?(scenario)
        begin
          # 2.0.x

          # We can bail early if this scenario's line is < the last feature
          # element's line
          outline = scenario.feature.feature_elements.last
          if scenario.source.last.location.line < outline.location.line
            return false
          end

          # Now the last feature element needs to be an outline - this is a
          # sanity check that makes later stuff easier
          if not outline.respond_to? :examples_tables
            return false
          end

          # The last row of the last examples tables is what we care about
          last_row = outline.examples_tables.last.example_rows.last

          # If the current scenario has the same location as the last example,
          # then we're the last scenario.
          return scenario.source.last.location.line == last_row.location.line

        rescue
          # 1.3.x
          if scenario.scenario_outline.feature.feature_elements.last == scenario.scenario_outline
            # And is this the last example in the table?
            is_last_example = false
            scenario.scenario_outline.each_example_row do |row|
              if row == scenario
                is_last_example = true
              else
                # Overwrite this again with 'false'
                is_last_example = false
              end
            end
            return is_last_example
          end
        end
      end
      raise "If you see this error it might indicate you're running an unsupported version of cucumber"
    end
  end # module Ast
end # module LapisLazuli
