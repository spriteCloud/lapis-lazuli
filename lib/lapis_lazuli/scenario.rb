#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
require "securerandom"
require "lapis_lazuli/storage"
require "lapis_lazuli/ast"

module LapisLazuli
  ##
  # Stores the Cucumber scenario
  # Includes timing, running state and a name
  class Scenario
    include LapisLazuli::Ast

    attr_reader :id, :time, :uuid, :data, :storage, :error
    attr_accessor :running, :check_browser_errors

    def initialize
      @uuid = SecureRandom.hex
      @storage = Storage.new
      @running = false
      @name = "start_of_test_run"
      self.update_timestamp
    end

    ##
    # Update the scenario with a new one
    def update(scenario)
      @uuid = SecureRandom.hex
      # Reset the fail attribute
      @check_browser_errors = true
      # The original scenario from cucumber
      @data = scenario
      # A name without special characters.
      @id = clean(scenario_id(scenario))
      self.update_timestamp
    end

    def update_timestamp
      now = Time.now
      # The current time
      @time = {
        :timestamp => now.strftime('%y%m%d_%H%M%S'),
        :iso_timestamp => now.utc.strftime("%FT%TZ"),
        :iso_short => now.utc.strftime("%y%m%dT%H%M%SZ"),
        :epoch => now.to_i.to_s
      }
    end

    def tags
      if !@data.nil?
        return @data.source_tag_names
      end
    end

    def scope(cleaned = false)
      scope = nil
      if @data.respond_to? :backtrace_line
        scope = @data.backtrace_line
      elsif @data.respond_to? :file_colon_line
        scope = @data.file_colon_line
      end

      if scope.nil?
        return nil
      elsif cleaned
        return clean [scope]
      else
        return scope
      end
    end

    private

    def clean(strings)
      result = []
      strings.each do |string|
        clean_string = string.gsub(/[^\w\.\-]/, ' ').strip.squeeze(' ').gsub(" ","_")
        result.push(clean_string)
      end
      return result.join("-").squeeze("-")
    end
  end
end
