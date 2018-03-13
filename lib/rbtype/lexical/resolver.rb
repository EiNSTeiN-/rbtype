require_relative 'named_context'
require_relative 'class_definition'
require_relative 'module_definition'
require_relative 'method_definition'
require_relative 'const_assignment'
require_relative 'include_reference'

module Rbtype
  module Lexical
    class Resolver
      def self.from_node(node, lexical_parent:)
        resolver = new
        resolver.process(node, lexical_parent)
        resolver
      end

      def process(node, lexical_parent)
        if node.is_a?(Array) || node.type == :begin
          node.to_a.each do |child|
            process(child, lexical_parent) if child.is_a?(::AST::Node)
          end
        elsif include_node?(node)
          lexical_parent.definitions << IncludeReference.from_node(node)
        elsif [:def, :defs].include?(node.type)
          lexical_parent.definitions << MethodDefinition.from_node(node, resolver: self, lexical_parent: lexical_parent)
        elsif node.type == :casgn
          lexical_parent.definitions << ConstAssignment.from_node(node, lexical_parent: lexical_parent)
        else
          if node.type == :class
            defn = ClassDefinition.from_node(node, resolver: self, lexical_parent: lexical_parent)
            lexical_parent.definitions << defn
          elsif node.type == :module
            defn = ModuleDefinition.from_node(node, resolver: self, lexical_parent: lexical_parent)
            lexical_parent.definitions << defn
          end
        end
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
