require_relative 'base'

module Rbtype
  module Lint
    class NestingMismatch < Base
      def run
        traverse do |object|
          next if object.definitions.size <= 1
          definitions = object.definitions.to_a
          expected_nesting = runtime.resolve_nesting(definitions[0].nesting)

          definitions[1..-1].each do |definition|
            nesting = runtime.resolve_nesting(definition.nesting)
            next if nesting == expected_nesting
            add_error(object, message: format(
              "`%s` at %s has a lexical nesting [%s], but another of its definition "\
              "at %s has a different lexical nesting [%s]. This may cause unexpexted "\
              "behavior because constant resolution in each location may find different "\
              "results for the same constant name.\n",
              object.name,
              format_location(definitions[0]),
              expected_nesting.map(&:path).map(&:to_s).join(', '),
              format_location(definition),
              nesting.map(&:path).map(&:to_s).join(', '),
            ))
          end
        end
      end

      private

      def snippet(definition)
        definition.location.source_line.strip
      end

      def format_definitions(definitions)
        format_list(
          definitions.map { |defn| "#{snippet(defn)} at #{format_location(defn)}" }
        )
      end
    end
  end
end
