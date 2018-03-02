module Rbtype
  module Namespace
    class SelfReference
      def initialize(node)
        @node = node
      end

      def self.from_node(node)
        if node.type == :self
          new(node)
        else
          raise ArgumentError, "cannot build name for #{node.type} node"
        end
      end

      def to_s
        :self
      end
    end
  end
end
