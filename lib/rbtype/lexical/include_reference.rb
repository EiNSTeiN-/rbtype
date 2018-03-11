require_relative 'const_reference'

module Rbtype
  module Lexical
    class IncludeReference
      attr_reader :target_ref

      def initialize(target_ref)
        @target_ref = target_ref
      end

      def self.from_node(node)
        if node.type == :send
          if [:const, :cbase].include?(node.children[2].type)
            target_ref = ConstReference.from_node(node.children[2])
            new(target_ref)
          end
        else
          loc = node.location.expression
          raise ArgumentError, "cannot build name for #{node.type} node at #{loc.source_buffer.name}:#{loc.line}"
        end
      end

      def to_s
        "include(#{target})"
      end
    end
  end
end
