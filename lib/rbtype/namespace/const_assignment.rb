require_relative 'const_reference'

module Rbtype
  module Namespace
    class ConstAssignment < NamedContext
      attr_reader :name_ref

      def initialize(ast, name_ref, full_name_ref, nesting)
        super(ast, name_ref, full_name_ref, nil, nil, nesting)
      end

      def self.from_node(node, nesting:)
        if node.type == :casgn
          namespace_ref = if node.children[0]
            ConstReference.from_node(node.children[0])
          else
            ConstReference.new
          end
          name_ref = namespace_ref.join(node.children[1])
          full_name_ref = nesting.first.join(name_ref)
          new(node, name_ref, full_name_ref, nesting)
        else
          loc = node.location.expression
          raise ArgumentError, "cannot build const definition for #{node.type} node at #{loc.source_buffer.name}:#{loc.line}"
        end
      end
    end
  end
end
