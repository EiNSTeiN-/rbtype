require_relative 'named_context'
require_relative 'receiver_reference'
require_relative 'self_reference'

module Rbtype
  module Lexical
    class MethodDefinition < NamedContext
      attr_reader :receiver_ref

      def initialize(node, receiver_ref, method_name, lexical_parent)
        @receiver_ref = receiver_ref
        super(node, method_name, nil, lexical_parent)
      end

      def self.from_node(node, resolver:, lexical_parent:)
        if node.type == :def
          receiver = nil
          method_name = node.children[0]
        elsif node.type == :defs
          receiver_ref = receiver_reference(node.children[0])
          method_name = node.children[1]
        else
          loc = node.location.expression
          raise ArgumentError, "cannot build method definition for #{node.type} node at #{loc.source_buffer.name}:#{loc.line}"
        end

        new(node, receiver_ref, method_name, lexical_parent)
      end

      def nesting
        lexical_parent.nesting
      end

      def self.receiver_reference(node)
        return unless node
        if node.type == :const
          ConstReference.from_node(node)
        elsif [:send, :lvar].include?(node.type)
          ReceiverReference.from_node(node)
        elsif node.type == :self
          SelfReference.from_node(node)
        else
          loc = node.location.expression
          raise ArgumentError, "cannot build receiver name for #{node.type} node at #{loc.source_buffer.name}:#{loc.line}"
        end
      end
    end
  end
end
