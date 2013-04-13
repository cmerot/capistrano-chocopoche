# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/chocopoche/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-chocopoche"
  spec.version       = Capistrano::Chocopoche::VERSION
  spec.authors       = ["Corentin Merot"]
  spec.email         = ["cmerot@themarqueeblink.com"]
  spec.description   = %q{Capistrano recipes and bin for mysql, rsync, php composer.}
  spec.summary       = %q{Chocopoche's Capistrano recipes}
  spec.homepage      = "https://github.com/chocopoche/capistrano-chocopoche"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "capistrano", "~> 2.14"

  spec.add_development_dependency "bundler", "~> 1.3"
end

