require_relative 'named_context'
require_relative 'class_definition'
require_relative 'module_definition'
require_relative 'method_definition'
require_relative 'const_assignment'
require_relative 'include_reference'
require_relative 'name_hierarchy'
require_relative 'name_definitions'

module Rbtype
  module Namespace
    class Resolver
      attr_reader :hierarchy

      def initialize
        @hierarchy = NameHierarchy.new(ConstReference.new([nil]))
      end

      def self.from_node(node, context:, nesting: nil)
        resolver = new
        nesting ||= [ConstReference.new([nil])]
        resolver.process(node, context, nesting)
        resolver
      end

      def process_from_root(node)
        nesting = Rbtype::Namespace::ConstReference.new([nil])
        context = Rbtype::Namespace::Context.new
        process(node, context, [nesting])
      end

      def process(node, context, nesting)
        if node.is_a?(Array) || node.type == :begin
          node.to_a.each do |child|
            process(child, context, nesting) if child.is_a?(::AST::Node)
          end
        elsif include_node?(node)
          context << IncludeReference.from_node(node)
        else
          defn = if node.type == :class
            ClassDefinition.from_node(node, resolver: self, nesting: nesting)
          elsif node.type == :module
            ModuleDefinition.from_node(node, resolver: self, nesting: nesting)
          elsif node.type == :casgn
            ConstAssignment.from_node(node, nesting: nesting)
          elsif [:def, :defs].include?(node.type)
            MethodDefinition.from_node(node, resolver: self, nesting: nesting)
          end

          if defn
            define_hierarchy(defn)
            context << defn
          end
        end
      end

      def define_hierarchy(defn)
        path = defn.definition_path.without_explicit_base
        where = path.empty? ? @hierarchy : @hierarchy.define_recursive(path, reference: defn)
        where.define(defn.definition_name, definition: defn)
      end

      def resolve_definitions(path)
        @hierarchy.find_recursive(path.without_explicit_base)&.definitions
      end

      def resolve_with_nesting(what, nesting)
        return if nesting.size <= 1
        path = nesting[1..nesting.size].find do |path|
          defs = resolve_definitions(path.join(what))
          defs && defs.size >= 1
        end
        path.join(what) if path
      end

      private

      def include_node?(node)
        node.type == :send &&
          node.children[0] == nil
          node.children[1] == :include
      end
    end
  end
end
