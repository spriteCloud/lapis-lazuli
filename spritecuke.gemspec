# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spritecuke/version'

Gem::Specification.new do |spec|
  spec.name          = "spritecuke"
  spec.version       = Spritecuke::VERSION
  spec.authors       = ["Mark Barzilay", "Jens Finkhaeuser"]
  spec.email         = ["mark@spritecloud.com", "jens@spritecloud.com"]
  spec.description   = %q{Cucumber helper functions and scaffolding for spriteCloud TA engineers.}
  spec.summary       = %q{Cucumber helper functions and scaffolding for spriteCloud TA engineers.}
  spec.homepage      = "https://github.com/spriteCloud/spritecuke"
  spec.license       = "Proprietary"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "thor"
end
