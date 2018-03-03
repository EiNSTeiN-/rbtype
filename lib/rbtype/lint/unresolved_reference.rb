require_relative 'base'

module Rbtype
  module Lint
    class UnresolvedReference < Base
      MSG = 'Class ancestor `%s` is not defined for class `%s` at %s'
      def run
        traverse do |name, definitions, references|
          definitions.each do |definition|
            check_superclass(name, definition) if definition.is_a?(Namespace::ClassDefinition)
          end
        end
      end

      private

      def check_superclass(name, definition)
        return unless superclass = definition.superclass_ref
        resolved = @resolver.resolve_with_nesting(superclass, definition.nesting)
        if resolved == nil
          add_error(name,
            message: format(MSG, superclass, name, format_location(definition)))
        end
      end
    end
  end
end
