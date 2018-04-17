# frozen_string_literal: true
module Rbtype
  class CLI
    class Describe
      def initialize(runtime, constants:, **options)
        @runtime = runtime
        @constants = constants
      end

      def to_s
        @constants.map do |const_ref|
          group = @runtime.find_const_group(const_ref)
          if group
            namespacing, definitions = group.partition(&:for_namespacing?)
            [
              "`#{group.full_path}` has #{definitions.size} relevant definition(s):",
              *locations(definitions),
              "`#{group.full_path}` is (re-)opened #{namespacing.size} time(s) for namespacing:",
              *locations(namespacing),
            ]
          else
            "`#{const_ref}`: not a known name"
          end
        end.flatten.compact.join("\n")
      end

      def locations(group)
        group.map { |defn| "  - `#{defn.source_line}` at #{defn.format_location}" }
      end
    end
  end
end
