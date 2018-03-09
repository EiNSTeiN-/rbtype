module Rbtype
  class CLI
    class Ancestors
      def initialize(resolver, ref)
        @resolver = resolver
        @ref = ref
      end

      def to_s
        if class_definitions.empty?
          "`#{@ref}` is not a class or has no class definition (only uses)"
        elsif class_ancestors.empty?
          "`#{@ref}` has no definitions with ancestors"
        else
          class_ancestors.map do |expr|
            class_ancestors_description(expr)
          end.flatten.join("\n")
        end
      end

      private

      def definitions
        @definitions ||= @resolver.resolve_definitions(@ref) || []
      end

      def class_definitions
        @class_definitions ||= definitions.select { |defn| defn.is_a?(Namespace::ClassDefinition) }
      end

      def class_ancestors
        @class_ancestors ||= class_definitions.map(&:superclass_expr).compact
      end

      def class_ancestors_description(expr)
        if expr.const?
          
        else
          "Ancestor is not a constant: `#{expr.node.location.expression.source_line}`"
        end
      end
    end
  end
end
