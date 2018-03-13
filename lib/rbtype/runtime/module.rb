require_relative 'object_space'

module Rbtype
  module Runtime
    class Module < ObjectSpace
      def type
        :module
      end
    end
  end
end
