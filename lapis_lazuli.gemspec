# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lapis_lazuli/version'

Gem::Specification.new do |spec|
  spec.name          = "lapis_lazuli"
  spec.version       = LapisLazuli::VERSION
  spec.authors       = ["Onno Steenbergen", "Gijs Paulides", "Mark Barzilay", "Jens Finkhaeuser"]
  spec.email         = ["foss@spritecloud.com"]
  spec.description   = %q{
    LapisLazuli provides cucumber helper functions and scaffolding for easier test
    automation suite development.

    A lot of functionality is aimed at dealing better with [Watir](http://watir.com/),
    or [appium](https://github.com/appium/appium), such as:

    - Easier/more reliable find and wait functionality for detecting UI elements.
    - Easier browser/device handling
    - Better error handling
    - etc.
  }
  spec.summary       = %q{Cucumber helper functions and scaffolding for easier test automation suite development.}
  spec.homepage      = "https://github.com/spriteCloud/lapis-lazuli"
  spec.license       = "MITNFA"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov"

  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "facets", "~> 2.9"
  spec.add_dependency "json", "~> 1.8"
  spec.add_dependency "faraday", "~> 0.9"
  spec.add_dependency "faraday_middleware", "~> 0.9"
  spec.add_dependency "faraday_json", "~> 0.1"
  spec.add_dependency "multi_xml", "~> 0.5"
  spec.add_dependency "teelogger", "~> 0.5"
  spec.add_dependency "minitest", "~> 5.5"
end
