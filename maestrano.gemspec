$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'maestrano/version'

Gem::Specification.new do |s|
  s.name = 'maestrano'
  s.version = Maestrano::VERSION
  s.summary = 'Ruby bindings for the Maestrano API'
  s.description = 'Maestrano is the next generation marketplace for SME applications. See https://maestrano.com for details.'
  s.authors = ['Arnaud Lachaume']
  s.email = ['arnaud.lachaume@maestrano.com']
  s.homepage = 'https://maestrano.com'
  s.license = 'MIT'

  s.files = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  
  s.add_dependency('rest-client', '~> 1.4')
  s.add_dependency('mime-types', '~> 1.25')
  s.add_dependency('json', '~> 1.8')
  
  s.add_development_dependency('test-unit', '~> 2')
  s.add_development_dependency('mocha', '~> 0.13')
  s.add_development_dependency('shoulda', '~> 2.11')
  s.add_development_dependency('timecop', '<= 0.6.0')
  s.add_development_dependency('rake', '~> 10')
  
  s.add_runtime_dependency("uuid", ["~> 2.3"])
  s.add_runtime_dependency("nokogiri", [">= 1.5.0"])
end
