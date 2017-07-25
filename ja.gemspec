# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ja/version"

Gem::Specification.new do |s|
  s.name          = "ja"
  s.version       = Ja::VERSION
  s.authors       = ["Oleksandr Sergiienko"]
  s.email         = ["sigerello@gmail.com"]
  s.summary       = "Ja makes you Rails app compliant to JSON API standard."
  s.homepage      = "https://github.com/sigerello/ja"
  s.license       = "MIT"
  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.4"

  s.add_development_dependency "bundler", "~> 1.15"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 3.0"

  s.add_dependency "rails", "~> 5.1"
end
