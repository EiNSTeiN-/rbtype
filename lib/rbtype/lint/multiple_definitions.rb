# frozen_string_literal: true
require_relative 'base'

module Rbtype
  module Lint
    class MultipleDefinitions < Base
      def run
        traverse do |group|
          next unless relevant_group?(group)
          relevant_definitions = group.reject { |defn| namespacing_definition?(defn) }
          next if relevant_definitions.size <= 1

          add_error(relevant_definitions.first, message: format(
            "`%s` has multiple relevant definitions (not used for namespacing). "\
            "This is not always an error, these classes or modules may be re-opened for monkey-patching, "\
            "but it may also indicate a problem with your namespace. All definitions reproduced below:\n%s\n",
            group.full_path,
            format_definitions(group).join("\n")
          ))
        end
      end

      private

      def relevant_group?(group)
        @lint_all_files ||
          @constants.include?(group.full_path) ||
          group.to_a.any? { |definition| !namespacing_definition?(definition) && @files.include?(definition.location.filename) }
      end

      def format_definitions(definitions)
        definitions.map do |definition|
          "#{definition.location.backtrace_line}#{' (for namespacing)' if namespacing_definition?(definition)}"
        end
      end
    end
  end
end
