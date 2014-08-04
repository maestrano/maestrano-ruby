module Maestrano
  module Account
    class Group < Maestrano::API::Resource
      include Maestrano::API::Operation::List
    end
  end
end