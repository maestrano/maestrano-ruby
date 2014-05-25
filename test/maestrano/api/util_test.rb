require File.expand_path('../../../test_helper', __FILE__)

module Maestrano
  module API
    class UtilTest < Test::Unit::TestCase
      should "symbolize_names should convert names to symbols" do
        start = {
          'foo' => 'bar',
          'array' => [{ 'foo' => 'bar' }],
          'nested' => {
            1 => 2,
            :symbol => 9,
            'string' => nil
          }
        }
        finish = {
          :foo => 'bar',
          :array => [{ :foo => 'bar' }],
          :nested => {
            1 => 2,
            :symbol => 9,
            :string => nil
          }
        }

        symbolized = Maestrano::API::Util.symbolize_names(start)
        assert_equal(finish, symbolized)
      end
    end
  end
end