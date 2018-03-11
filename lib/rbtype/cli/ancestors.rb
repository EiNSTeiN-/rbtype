module Rbtype
  class CLI
    class Ancestors
      def initialize(resolver, ref)
        @resolver = resolver
        @ref = ref
      end

      def to_s
        defs = definitions_for(@ref)
        class_ancestors_description(@ref, defs)
      end

      private

      def definitions_for(ref)
        @resolver.resolve_definitions(ref) || []
      end

      def class_definitions_for(defs)
        defs.select { |defn| defn.is_a?(Lexical::ClassDefinition) }
      end

      def class_ancestors_for(defs)
        class_definitions_for(defs).map(&:superclass_expr).compact
      end

      def class_ancestors_description(ref, defs)
        if class_definitions_for(defs).empty?
          "`#{ref}` is not a class or has no class definition (only uses)"
        elsif class_ancestors_for(defs).empty?
          "`#{ref}` has no definitions with ancestors (end of hierarchy)"
        else
          if expr = class_ancestors_for(defs).find { |expr| !expr.const? }
            "`#{ref}` has an ancestor that is not a constant: `#{expr.node.location.expression.source_line}` #{expr}"
          else
            refs = class_ancestors_for(defs).map { |expr| expr.const_reference }
            names = refs.map { |ref| @resolver.resolve_name(ref) }.uniq
            if names.size > 1
              names_list = names.map { |name| name&.full_name || '(unresolved)' }.join(', ')
              "`#{ref}` has multiple class definitions, and not all of them "\
                "resolve to the same constant: #{names_list}"
            elsif names.any?(&:nil?)
              "`#{ref}` is not defined"
            else
              name = names.first
              [
                "`#{ref}` inherits from `#{name.full_name}`",
                class_ancestors_description(name.full_name, name.definitions),
              ].compact.join("\n")
            end
          end
        end
      end
    end
  end
end
