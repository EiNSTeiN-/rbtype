require_relative 'base'

module Rbtype
  module Lint
    class ConflictingDefinition < Base
      def run
        traverse do |name, definitions|
          next if definitions.size <= 1
          check_definition_type(name, definitions)
          check_class_ancestors(name, definitions)
        end
      end

      private

      def check_definition_type(name, definitions)
        defs = definitions
          .reject { |defn| defn.is_a?(Rbtype::Namespace::ConstAssignment) }
          .uniq(&:class)
        return if defs.size <= 1
        add_error(name, message: format(
          "Conflicting definitions for %s were resolved to:\n%s", name,
          format_definition_list(defs)))
      end

      def check_class_ancestors(name, definitions)
        ancestors = definitions.map do |definition|
          if superclass = definition.superclass_expr&.const_reference
            found = @resolver.resolve_with_nesting(superclass, definition.nesting)
            [found || "(not resolved #{superclass})", definition]
          else
            next #['(no parent)', definition]
          end
        end
        ancestors = ancestors.compact.uniq(&:first)
        return if ancestors.size <= 1
        add_error(name, message: format(
          "Conflicting ancestors for `%s` were resolved to:\n%s", name,
          format_ancestors_list(ancestors)))
      end

      def format_ancestors_list(ancestors)
        list = ancestors.map { |path, defn| "#{path.to_s} at #{format_location(defn)}" }
        format_list(list)
      end

      def format_definition_list(defs)
        list = defs.map { |defn| "#{defn.class} at #{format_location(defn)}" }
        format_list(list)
      end
    end
  end
end
