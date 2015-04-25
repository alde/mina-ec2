# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mina/ec2/version'

Gem::Specification.new do |spec|
  spec.name          = "mina-ec2"
  spec.version       = Mina::EC2::VERSION
  spec.authors       = ["Rickard Dybeck"]
  spec.email         = ["r.dybeck@gmail.com"]
  spec.description   = %q{Adds support for Mina to deploy to EC2}
  spec.summary       = %q{Adds support for Mina to deploy to EC2}
  spec.homepage      = "http://github.com/alde/mina-ec2"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mina", ">= 0.2.1"
  spec.add_dependency "aws-sdk-v1"
  spec.add_dependency 'parallel'

  spec.add_development_dependency "bundler", ">= 1.3.5"
  spec.add_development_dependency "rake"
end
