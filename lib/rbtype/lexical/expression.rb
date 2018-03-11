module Rbtype
  module Lexical
    class Expression
      attr_reader :node

      def initialize(node)
        raise ArgumentError, "node is nil" unless node
        @node = node
      end

      def self.from_node(node)
        new(node)
      end

      def type
        @node.type
      end

      def const?
        type == :const || type == :cbase
      end

      def const_reference
        ConstReference.from_node(@node) if const?
      end

      def to_s
        loc = @node.location.expression
        "(expression at #{loc.source_buffer.name}:#{loc.line})"
      end

      def inspect
        "#<#{self.class.name} #{self}>"
      end
    end
  end
end
