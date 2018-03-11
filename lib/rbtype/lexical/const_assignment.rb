require_relative 'const_reference'

module Rbtype
  module Lexical
    class ConstAssignment
      attr_reader :ast, :name_ref, :lexical_parent, :value_node

      def initialize(ast, name_ref, lexical_parent)
        @ast = ast
        @name_ref = name_ref
        @lexical_parent = lexical_parent
        @value_node = ast.children[2]
      end

      def self.from_node(node, lexical_parent:)
        if node.type == :casgn
          namespace_ref = if node.children[0]
            ConstReference.from_node(node.children[0])
          else
            ConstReference.new
          end
          name_ref = namespace_ref.join(node.children[1])
          new(node, name_ref, lexical_parent)
        else
          loc = node.location.expression
          raise ArgumentError, "cannot build const definition for #{node.type} node at #{loc.source_buffer.name}:#{loc.line}"
        end
      end

      def value_type
        Type::Engine.run(value_node).type_identity
      end
    end
  end
end
