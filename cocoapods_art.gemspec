# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods_art'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-art'
  spec.version       = CocoaPodsArt::VERSION
  spec.authors       = ['Dan Feldman']
  spec.email         = ['art-dev@jfrog.com']
  spec.description   = %q{Enables you to use Artifactory as your spec repo, as well as a repository for your pods}
  spec.summary       = %q{Artifactory support for CocoaPods}
  spec.homepage      = 'https://github.com/JFrogDev/cocoapods-art'
  spec.license       = 'Apache-2.0'

  spec.files = Dir['lib/**/*.rb']
  spec.files += Dir['[A-Z]*'] + Dir['test/**/*']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0.2'
  spec.add_development_dependency 'rake',    '~> 13'
end
