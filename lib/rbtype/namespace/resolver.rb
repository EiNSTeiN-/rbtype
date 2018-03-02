require_relative 'named_context'
require_relative 'class_definition'
require_relative 'module_definition'
require_relative 'method_definition'
require_relative 'const_definition'
require_relative 'include_reference'
require_relative 'name_hierarchy'
require_relative 'name_definitions'

module Rbtype
  module Namespace
    class Resolver
      attr_reader :hierarchy

      def initialize
        @hierarchy = NameHierarchy.new
      end

      def self.from_node(node, context:, nesting: nil)
        namespace = new
        nesting ||= [ConstReference.new([nil])]
        namespace.process(node, context, nesting)
        namespace
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
            ConstDefinition.from_node(node, nesting: nesting)
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
        where = path.empty? ? @hierarchy : @hierarchy.define_recursive(path)
        where.define(defn.definition_name, defn)
      end

      def resolve_definitions(path)
        @hierarchy.find_recursive(path)&.definitions
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
