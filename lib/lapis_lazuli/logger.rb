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
    def initialize(name, io = STDOUT)
      # Store the name for later usage
      @filename = name
      # Create the logger
      @file = File.new(@filename, File::WRONLY | File::APPEND | File::CREAT)
      @log = Logger.new @file
      # IO handle
      @io = io
      # Write that we are logging to this file
      self.info("Logging to '#{@filename}'")
    end

    ##
    # Set log level; override this to also accept strings
    def level=(val)
      # Convert strings to the constant value
      if val.is_a? String
        begin
          val = Logger.const_get val
        rescue NameError
          val = Logger::WARN
        end
      end

      # Whatever the result of the above, try to set the log level
      @log.level = val
    end


    ##
    # Log an exception
    def exception(message, ex)
      self.error("#{message} got #{ex.message}:\n#{ex.backtrace.join("\n")}")
    end

    ##
    # Every function this class doesn't have should be mapped to the original
    # logger
    def respond_to?(meth)
      if !@log.nil? and @log.respond_to? meth
        return true
      end
      return super
    end

    def method_missing(meth, *args, &block)
      # Write to IO stream and the logger
      if !@log.nil? and @log.respond_to? meth
        if args.length > 1
          @io.write("#{meth}: #{args}\n")
        else
          @io.write("#{meth}: #{args[0]}\n")
        end
        @io.flush()
        # Call the logger
        return @log.send(meth.to_s, *args, &block)
      end
      return super
    end
  end
end
