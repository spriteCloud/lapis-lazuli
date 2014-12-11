#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2014 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
module LapisLazuli
  class Formatter
    def initialize(runtime, io, options, *args)
      @runtime = runtime
      @io = io
      @options = options
      @args = args
    end

    def exception(error, status, *args)
      ll = LapisLazuli::World.instance
      ll.scenario.update_error(error)
    end

    # Fake responding to everything else.
    def respond_to?(*args)
      true
    end

    def method_missing(meth, *args, &block)
      # @io.write("Called #{meth}\n")
      # @io.flush
    end

  end # class CucumberFormatter
end # module LapisLazuli
