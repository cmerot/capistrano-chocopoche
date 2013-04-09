# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "capistrano-chocopoche"
  spec.version       = "0.0.2"
  spec.authors       = ["Corentin Merot"]
  spec.email         = ["cmerot@themarqueeblink.com"]
  spec.description   = %q{Capistrano recipes, with another railsless-deploy and a files utility.}
  spec.summary       = %q{Chocopoche's Capistrano recipes}
  spec.homepage      = "https://github.com/chocopoche/capistrano-chocopoche"
  spec.license       = "MIT"
  spec.files         = `git ls-files`.split($/)
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
end

