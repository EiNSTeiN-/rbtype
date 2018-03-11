require_relative 'unnamed_context'
require_relative 'const_reference'
require_relative 'include_reference'

module Rbtype
  module Lexical
    class NamedContext < UnnamedContext
      attr_reader :ast, :name_ref, :superclass_expr, :lexical_parent

      def initialize(ast, name_ref, superclass_expr, lexical_parent)
        raise 'lexical_parent must be defined' if lexical_parent.nil?
        @ast = ast
        @name_ref = name_ref
        @superclass_expr = superclass_expr
        super(lexical_parent)
      end

      def to_s
        "class #{name_ref}"
      end

      def inspect
        "#<#{self.class} #{name_ref}>"
      end

      def location
        ast&.location&.expression
      end

      def nesting
        [self, *lexical_parent.nesting]
      end

      def self.from_node(node, resolver:, lexical_parent:)
        name_node = node.children[0]
        name_ref = ConstReference.from_node(name_node)
        superclass_expr = if node.type == :class && node.children[1]
          Expression.from_node(node.children[1]) if node.children[1]
        end
        obj = new(node, name_ref, superclass_expr, lexical_parent)
        resolver.process(node.children, obj)
        obj
      end
    end
  end
end
