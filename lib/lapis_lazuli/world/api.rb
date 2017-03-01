#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#

require "lapis_lazuli/api"
require "lapis_lazuli/runtime"

module LapisLazuli
module WorldModule
  ##
  # Module managing an API instance
  module API

    ##
    # Has API?
    def has_api?
      a = Runtime::instance.get :api
      return !a.nil?
    end

    ##
    # Get/create the API instance
    def api
      return Runtime.instance.set_if(self, :api) do
        LapisLazuli::API.new
      end
    end

  end # module API
end # module WorldModule
end # module LapisLazuli
