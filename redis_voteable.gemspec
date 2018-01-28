# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_voteable/version'

Gem::Specification.new do |spec|
  spec.name          = 'redis_voteable'
  spec.version       = RedisVoteable::VERSION
  spec.authors       = ['Chris Brauchli']
  spec.email         = ['cbrauchli@gmail.com']
  spec.description   = 'A Redis-backed voting extension for Rails applications.'
  spec.summary       = 'Simple vote management with Redis used as the backend.'
  spec.homepage      = 'http://github.com/cbrauchli/redis_voteable'
  spec.date          = '2011-09-30'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'redis', '>= 3.0.0'
  spec.add_dependency 'activesupport', '>= 3.2.0'

  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'sqlite3'
end
