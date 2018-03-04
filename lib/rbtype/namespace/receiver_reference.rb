require_relative 'const_reference'

module Rbtype
  module Namespace
    class ReceiverReference
      attr_reader :receiver_ref, :method_name

      def initialize(receiver_ref, method_name)
        @receiver_ref = receiver_ref
        @method_name = method_name
      end

      def self.from_node(node)
        if node.type == :lvar
          new(nil, node)
        elsif node.type == :send
          receiver_ref = if (receiver_node = node.children[0])
            if receiver_node.type == :const
              ConstReference.from_node(receiver_node)
            else
              from_node(receiver_node)
            end
          end
          new(receiver_ref, node.children[1])
        else
          loc = node.location.expression
          raise ArgumentError, "cannot build name for #{node.type} node at #{loc.source_buffer.name}:#{loc.line}"
        end
      end

      def to_s
        if receiver_ref
          "#{receiver_ref}.#{method_name}"
        else
          method_name.to_s
        end
      end
    end
  end
end
