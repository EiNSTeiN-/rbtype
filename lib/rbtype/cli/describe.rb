module Rbtype
  class CLI
    class Describe
      def initialize(runtime, ref)
        @runtime = runtime
        @ref = ref
      end

      def to_s
        out = [
          object.inspect,
          "Has named defined: #{object&.names}",
          definitions_descriptions
        ]

        out.compact.join("\n")
      end

      def definitions_descriptions
        if definitions == nil
          "`#{@ref}` is not a known name"
        elsif definitions.empty?
          "`#{@ref}` has no definitions"
        else
          descriptions = definitions.map { |d| description(d) }
          <<~EOS
            `#{@ref}` has #{definitions.size} definitions:
             - #{descriptions.join("\n - ")}
          EOS
        end
      end

      def description(definition)
        loc = definition.location
        "a #{friendly_name(definition)} at #{loc.source_buffer.name}:#{loc.line}"
      end

      def definitions
        object&.definitions
      end

      def object
        @object ||= @runtime.find_const(@ref)
      end
    end
  end
end
