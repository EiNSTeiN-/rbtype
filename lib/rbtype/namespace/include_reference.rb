require_relative 'const_reference'

module Rbtype
  module Namespace
    class IncludeReference
      attr_reader :target_ref

      def initialize(target_ref)
        @target_ref = target_ref
      end

      def self.from_node(node)
        if node.type == :send
          target_ref = ConstReference.from_node(node.children[2])
          new(target_ref)
        else
          raise ArgumentError, "cannot build name for #{node.type} node"
        end
      end

      def to_s
        "include(#{target})"
      end
    end
  end
end
