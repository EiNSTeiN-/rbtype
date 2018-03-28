require_relative 'const_reference'

module Rbtype
  module Lexical
    class IncludeReference
      attr_reader :ast, :target_ref

      def initialize(ast, target_ref)
        @ast = ast
        @target_ref = target_ref
      end

      def self.from_node(node)
        if node.type == :send
          if [:const, :cbase].include?(node.children[2].type)
            target_ref = ConstReference.from_node(node.children[2])
            new(node, target_ref)
          end
        else
          loc = node.location.expression
          raise ArgumentError, "cannot build include reference for #{node.type} node at #{loc.source_buffer.name}:#{loc.line}"
        end
      end

      def type
        :include_reference
      end

      def location
        @location ||= ast&.location&.expression
      end

      def to_s
        "include(#{target_ref})"
      end
    end
  end
end
