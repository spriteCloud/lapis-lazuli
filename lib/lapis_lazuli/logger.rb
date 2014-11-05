require "logger"

module LapisLazuli
  class TeeLogger
    @filename
    @log

    def initialize(name)
      @filename = name
      @log = Logger.new(filename)
      self.info("Logging to '#{@filename}'")
    end

    def exception(message, ex)
      self.error("#{message} got #{ex.message}:\n#{ex.backtrace.join("\n")}")
    end

    def method_missing(meth, *args, &block)
      if @log.respond_to? meth
        if args.length > 1
          STDOUT.write("#{meth}: #{args}\n")
        else
          STDOUT.write("#{meth}: #{args[0]}\n")
        end
        STDOUT.flush()
        @log.send(meth.to_s, *args, &block)
      end
    end
  end
end
