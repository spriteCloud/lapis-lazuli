#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2015 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

module LapisLazuli
  ##
  # Convenience module for dealing with aspects of the cucumber AST. From
  # version 1.3.x to version 2.0.x, some changes were introduced here.
  module Ast
    ##
    # Return a unique and human parsable ID for scenarios
    def scenario_id(obj)
      # For 2.0.x, the best scenario ID is one prefixed by the file name + line
      # number, followed by the feature name, scenario name, and table data (if
      # applicable).
      if is_cucumber_2?(obj)
        id = [obj.location.to_s]
        for i in 0 .. obj.source.length - 1 do
          part = obj.source[i]
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
    def is_cucumber_2?(obj)
      begin
        # The assumption - FIXME perhaps wrong - is that cucumber 1.3.x does not
        # have this source array.
        return (obj.respond_to?(:source) and obj.source.is_a?(Array))
      rescue
        return false
      end
    end


    ##
    # Tests whether the scenario object is a single scenario
    def is_scenario?(obj)
      begin
        # 1.3.x
        return obj == Cucumber::Ast::Scenario
      rescue
        # 2.0.x - everything is a Cucumber::Core::Test::Case
        # Source contains a Feature and a Scenario object
        return obj.source.length == 2
      end
    end


    ##
    # Tests whether the scenario object is a table row
    def is_table_row?(obj)
      begin
        # 1.3.x
        return obj == Cucumber::Ast::OutlineTable::ExampleRow
      rescue
        # 2.0.x - everything is a Cucumber::Core::Test::Case
        # Source contains a Feature and a Scenario object, as well as an example
        # and row object
        return obj.source.length > 2
      end
    end
  end # module Ast
end # module LapisLazuli
