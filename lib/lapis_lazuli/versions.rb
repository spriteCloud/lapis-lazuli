#
# LapisLazuli
# https://github.com/spriteCloud/lapis-lazuli
#
# Copyright (c) 2013-2017 spriteCloud B.V. and other LapisLazuli contributors.
# All rights reserved.
#
require 'lapis_lazuli/api'

module LapisLazuli

  ##
  # Given a versions string or hash, stores it for later use with the library.
  attr_accessor :software_versions
  extend self

  ##
  # Connedt to the endpoint or to ENV['VERSION_ENDPOINT'], then retrieve the
  # url. The contents should be the software versions used.
  def self.fetch_versions(url, endpoint = nil)
    # Set the connection endpoint. This is either the endpoint, or the
    # environment variable 'VERSION_ENDPOINT'.
    if ENV.has_key?('VERSION_ENDPOINT')
      endpoint = ENV['VERSION_ENDPOINT']
    end

    # Connect to the endpoint
    api = API.new
    api.set_conn(endpoint)

    # Fetch versions
    response = api.get(url)
    if 2 != response.status / 100
      raise "Error retrieving software versions, got status code #{response.status}"
    end

    # Store that stuff for later.
    self.software_versions = response.body
  end
end # module LapisLazuli
