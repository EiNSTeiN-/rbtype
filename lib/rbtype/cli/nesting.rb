# frozen_string_literal: true
module Rbtype
  class CLI
    class Nesting
      def initialize(runtime, constants:, **options)
        @runtime = runtime
        @constants = constants
      end

      def to_s
        @constants.map do |const_ref|
          group = @runtime.find_const_group(const_ref)
          if group
            <<~EOS
              `#{group.full_path}` has #{group.size} definition(s):
               #{descriptions(group).join(" ")}
            EOS
          else
            "`#{const_ref}` is not a known name"
          end
        end.join("\n")
      end

      def description(defn)
        <<~EOS
          - at #{defn.format_location}
             #{defn.nesting.map(&:full_path).join(' -> ')}
        EOS
      end

      def descriptions(group)
        group.map { |defn| description(defn) }
      end
    end
  end
end
