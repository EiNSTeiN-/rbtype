module Rbtype
  module Lexical
    class SelfReference
      def initialize(node)
        @node = node
      end

      def self.from_node(node)
        if node.type == :self
          new(node)
        else
          loc = node.location.expression
          raise ArgumentError, "cannot build name for #{node.type} node at #{loc.source_buffer.name}:#{loc.line}"
        end
      end

      def to_s
        :self
      end
    end
  end
end
