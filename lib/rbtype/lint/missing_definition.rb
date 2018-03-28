require_relative 'base'

module Rbtype
  module Lint
    class MissingDefinition < Base
      def run
        traverse do |object|
          next if object.top_level?
          if object.definitions.size == 0
            add_error(object, message: format(
              "Missing definition for %s\n%s\n",
              object.path,
              format_references_list(object.references)
            ))
          end
        end

        runtime.delayed_definitions.each do |delayed_definition|
          add_error(delayed_definition.parent, message: format(
            "Could not resolve `%s` in context of `%s` so declaration `%s` was ignored\n%s\n",
            delayed_definition.definition.name_ref[0],
            delayed_definition.parent,
            delayed_definition.definition.name_ref,
            format_references_list([delayed_definition.definition])
          ))
        end
      end

      def format_references_list(references)
        format_list(
          references.map { |ref| "referenced in `#{ref.location.source_line.strip}` at #{format_location(ref)}" }
        )
      end
    end
  end
end
