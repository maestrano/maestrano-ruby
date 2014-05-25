task :default => [:test]

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

Rake::TestTask.new(:saml) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/maestrano/saml/**/*_test.rb'
  test.verbose = true
end

Rake::TestTask.new(:api) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/maestrano/api/**/*_test.rb'
  test.verbose = true
end

Rake::TestTask.new(:sso) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/maestrano/sso{_test.rb,/**/*_test.rb}'
  test.verbose = true
end

Rake::TestTask.new(:xmlsec) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/maestrano/xml_security/**/*_test.rb'
  test.verbose = true
end