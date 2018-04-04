require_relative 'base'

module Rbtype
  module Lint
    class LexicalPathMismatch < Base
      def run
        traverse do |group|
          group.each do |definition|
            actual_path = definition.full_path
            parts = definition.nesting.reverse.map(&:path)
            lexical_path = parts.reduce(Constants::ConstReference.base) { |current, other| current.join(other) }
            if lexical_path != actual_path
              add_error(definition, message: format(
                "`%s` at %s "\
                "was defined at `%s`, but its lexical definition indicates it should be "\
                " defined at `%s` instead. This occurs when a compact name is used to "\
                "define a constant and its name resolves to an unepxected location. "\
                "Inspect the following location(s):\n%s\n",
                definition.source_line,
                definition.format_location,
                actual_path,
                lexical_path,
                format_namespaced_definitions(definition.nesting)
              ))
            end
          end
        end
      end

      private

      def format_namespaced_definitions(nesting)
        format_list(
          nesting
            .select { |defn| defn.namespaced? }
            .map { |defn| "#{defn.source_line} at #{defn.format_location}" }
        )
      end
    end
  end
end
