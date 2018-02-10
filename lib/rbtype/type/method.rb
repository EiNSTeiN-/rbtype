module Rbtype
  module Type
    class Method
      attr_reader :node

      def initialize(node)
        @node = node
      end
    end
  end
end
