# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slicing/version'

Gem::Specification.new do |spec|
  spec.name          = "slicing"
  spec.version       = Slicing::VERSION
  spec.authors       = ["Bryan Lim"]
  spec.email         = ["ytbryan@gmail.com"]
  spec.summary       = %q{}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ["slicing"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
