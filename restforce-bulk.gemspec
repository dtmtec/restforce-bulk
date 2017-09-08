# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'restforce/bulk/version'

Gem::Specification.new do |spec|
  spec.name          = "restforce-bulk"
  spec.version       = Restforce::Bulk::VERSION
  spec.authors       = ["Vicente Mundim"]
  spec.email         = ["vicente.mundim@gmail.com"]

  spec.summary       = %q{Client for Salesforce Bulk API}
  spec.description   = %q{Client for Salesforce Bulk API}
  spec.homepage      = "https://github.com/dtmtec/restforce-bulk"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "restforce", "~> 2.1"
  spec.add_dependency "nokogiri"
  spec.add_dependency "multi_xml"
  spec.add_dependency "activesupport", "> 4.2.4"
  spec.add_dependency "rubyzip", "~> 1.1.7"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
end
