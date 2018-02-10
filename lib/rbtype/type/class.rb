module Rbtype
  module Type
    class Class
      attr_reader :node

      def initialize(node)
        @node = node
      end
    end
  end
end
