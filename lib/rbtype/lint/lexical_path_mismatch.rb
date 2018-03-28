require_relative 'base'

module Rbtype
  module Lint
    class LexicalPathMismatch < Base
      def run
        traverse_definitions do |definition|
          actual_object = runtime.object_from_definition(definition)
          next unless actual_object

          parts = definition.nesting.reverse.select { |defn| defn.is_a?(Lexical::NamedContext) }.map(&:name_ref)
          lexical_path = parts.reduce(Lexical::ConstReference.base) { |current, other| current.join(other) }
          actual_path = actual_object.path

          if lexical_path != actual_path
            add_error(actual_object, message: format(
              "`%s` at %s "\
              "was defined at `%s`, but its lexical definition indicates it should be "\
              " defined at `%s` instead. This occurs when a compact name is used to "\
              "define a constant and its name resolves to an unepxected location. "\
              "Inspect the following location(s):\n%s\n",
              snippet(definition),
              format_location(definition),
              actual_path,
              lexical_path,
              format_namespaced_definitions(definition.nesting)
            ))
          end
        end
      end

      private

      def snippet(definition)
        definition.location.source_line.strip
      end

      def format_namespaced_definitions(nesting)
        format_list(
          nesting
            .select { |defn| defn.respond_to?(:namespaced?) && defn.namespaced? }
            .map { |defn| "#{snippet(defn)} at #{format_location(defn)}" }
        )
      end
    end
  end
end
