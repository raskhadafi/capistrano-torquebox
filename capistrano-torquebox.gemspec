# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'capistrano/torquebox/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-torquebox"
  spec.version       = Capistrano::Torquebox::Version
  spec.authors       = ["Roman Simecek"]
  spec.email         = ["roman@good2go.ch"]
  spec.summary       = %q{Torquebox support for Capistrano 3.x}
  spec.description   = %q{Torquebox support for Capistrano 3.x}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'capistrano', '~> 3.0'
  spec.add_dependency 'sshkit', '>= 1.2.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
