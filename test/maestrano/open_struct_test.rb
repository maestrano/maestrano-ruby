require File.expand_path('../../test_helper', __FILE__)

module Maestrano
  class MaestranoOpenStructTest < Test::Unit::TestCase
    should "return the right attributes" do
      o = Maestrano::OpenStruct.new(bla: 'hello', ha: 'yo')
      assert_equal [:bla, :ha], o.attributes
    end
  end
end
