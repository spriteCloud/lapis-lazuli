#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
require "logger"

module LapisLazuli
  ##
  # Logger that writes to the STDOUT and a file
  class TeeLogger
    @filename
    @log

    ##
    # Start with a filename
    def initialize(name)
      # Store the name for later usage
      @filename = name
      # Create the logger
      @log = Logger.new(filename)
      # Write that we are logging to this file
      self.info("Logging to '#{@filename}'")
    end

    ##
    # Log an exception
    def exception(message, ex)
      self.error("#{message} got #{ex.message}:\n#{ex.backtrace.join("\n")}")
    end

    ##
    # Every function this class doesn't have should be mapped to the original
    # logger
    def method_missing(meth, *args, &block)
      # Write to STDOUT
      if @log.respond_to? meth
        if args.length > 1
          STDOUT.write("#{meth}: #{args}\n")
        else
          STDOUT.write("#{meth}: #{args[0]}\n")
        end
        STDOUT.flush()
        # Call the logger
        @log.send(meth.to_s, *args, &block)
      end
    end
  end
end
