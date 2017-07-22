# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gehirn_dns/version'

Gem::Specification.new do |spec|
  spec.name          = 'gehirn_dns'
  spec.version       = GehirnDns::VERSION
  spec.authors       = ['kyontan']
  spec.email         = ['kyontan@monora.me']

  spec.summary       = 'The Gehirn DNS API client for Ruby'
  spec.description   = 'The Gehirn DNS API client for Ruby'
  spec.homepage      = 'https://github.com/kyontan/gehirn_dns'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
