require_relative 'context'
require_relative 'const_reference'
require_relative 'include_reference'

module Rbtype
  module Namespace
    class NamedContext
      attr_reader :ast, :name_ref, :superclass_ref, :context, :nesting, :full_name_ref

      def initialize(ast, name_ref, full_name_ref, superclass_ref, context, nesting)
        raise 'name must be given' unless name_ref
        raise 'full name must be given' unless full_name_ref
        raise 'nesting from cbase must be given' unless nesting && nesting.size > 0
        @ast = ast
        @name_ref = name_ref
        @full_name_ref = full_name_ref
        @superclass_ref = superclass_ref
        @context = context
        @nesting = nesting
      end

      def location
        ast&.location&.expression
      end

      def include_references
        context.select { |entry| entry.is_a?(IncludeReference) }
      end

      def definition_path
        if full_name_ref.size <= 1
          ConstReference.new
        else
          full_name_ref[0..-2]
        end
      end

      def definition_name
        full_name_ref[-1]
      end

      def included_consts
        include_references.map(&:target_ref)
      end

      def self.from_node(node, resolver:, nesting: nil)
        context = Context.new
        name_node = node.children[0]
        name_ref = ConstReference.from_node(name_node)
        superclass_ref = if node.type == :class
          ConstReference.from_node(node.children[1]) if node.children[1]
        end
        new_nesting = [nesting.first.join(name_ref), *nesting]
        full_name_ref = new_nesting.first
        obj = new(node, name_ref, full_name_ref, superclass_ref, context, new_nesting)
        resolver.process(node.children, context, new_nesting)
        obj
      end
    end
  end
end
