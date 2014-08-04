module Maestrano
  module Account
    class User < Maestrano::API::Resource
      include Maestrano::API::Operation::List
    end
  end
end