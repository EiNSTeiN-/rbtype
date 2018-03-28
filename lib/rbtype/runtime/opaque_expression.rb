require_relative 'object_space'

module Rbtype
  module Runtime
    class OpaqueExpression < ::Rbtype::Runtime::ObjectSpace
      attr_reader :expression

      def initialize(expression, parent:, reference:)
        super(parent)
        @expression = expression
        self.references << reference if reference
      end

      def type
        :opaque_expression
      end

      def ancestors
        [self]
      end

      def to_s
        "#{type}(#{expression})"
      end

      def inspect
        "#<#{self.class} #{self}>"
      end
    end
  end
end
