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
        defs = definitions.uniq(&:class)
        return if defs.size <= 1
        locs = defs.map { |defn| format_location(defn) }.join(', ')
        add_error(name,
          message: format('Conflicting definitions for %s (see %s)', name, locs))
      end

      def check_class_ancestors(name, definitions)
        ancestors = definitions.map do |definition|
          if superclass = definition.superclass_ref
            found = @resolver.resolve_with_nesting(superclass, definition.nesting)
            [found || "(not resolved #{superclass})", definition]
          else
            ['(no parent)', definition]
          end
        end
        ancestors.uniq!(&:first)
        return if ancestors.size <= 1
        add_error(name, message: format(
          "Conflicting ancestors for `%s` were resolved to:\n%s", name,
          format_ancestors_list(ancestors)))
      end

      def format_ancestors_list(ancestors)
        list = ancestors.map { |path, defn| "#{path.to_s} at #{format_location(defn)}" }
        format_list(list)
      end
    end
  end
end
