require 'maestrano'
require 'test/unit'
require 'shoulda'
require 'ruby-debug'
require 'mocha/setup'
require 'timecop'

# Require all helpers
Dir[File.expand_path(File.join(File.dirname(__FILE__),"helpers/**/*.rb"))].each {|f| require f}

class Test::Unit::TestCase
end