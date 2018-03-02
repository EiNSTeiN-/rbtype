require_relative 'named_context'
require_relative 'receiver_reference'
require_relative 'self_reference'

module Rbtype
  module Namespace
    class MethodDefinition < NamedContext
      attr_reader :receiver_ref

      def initialize(node, receiver_ref, method_name, context, nested_into)
        @receiver_ref = receiver_ref
        if receiver_ref&.is_a?(ConstReference)
          nested_into.first.join!(receiver_ref)
        end
        full_name_ref = nested_into.first.join(method_name)
        super(node, method_name, full_name_ref, nil, context, nested_into)
      end

      def self.from_node(node, resolver:, nesting:)
        if node.type == :def
          receiver = nil
          method_name = node.children[0]
        elsif node.type == :defs
          receiver_ref = receiver_reference(node.children[0])
          method_name = node.children[1]
        else
          raise ArgumentError, "cannot build method definition for #{node.type} node"
        end

        context = Context.new
        obj = new(node, receiver_ref, method_name, context, nesting)
        resolver.process(node.children, context, nesting)
        obj
      end

      def self.receiver_reference(node)
        return unless node
        if node.type == :const
          ConstReference.from_node(node)
        elsif node.type == :send
          ReceiverReference.from_node(node)
        elsif node.type == :self
          SelfReference.from_node(node)
        else
          raise ArgumentError, "cannot build receiver name for #{node.type} node"
        end
      end
    end
  end
end
