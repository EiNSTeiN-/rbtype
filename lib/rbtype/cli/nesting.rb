module Rbtype
  class CLI
    class Nesting
      def initialize(resolver, ref)
        @resolver = resolver
        @ref = ref
      end

      def to_s
        if definitions == nil
          "`#{@ref}` is not a known name"
        elsif definitions.empty?
          "`#{@ref}` has no definitions"
        else
          descriptions = definitions.map { |d| description(d) }
          <<~EOS
            `#{@ref}` has #{definitions.size} definitions:
             #{descriptions.join(" ")}
          EOS
        end
      end

      def description(definition)
        loc = definition.location
        <<~EOS
          - at #{loc.source_buffer.name}:#{loc.line}
             #{definition.nesting.map(&:to_s).join(' -> ')}
        EOS
      end

      def definitions
        @definitions ||= @resolver.resolve_definitions(@ref)
      end
    end
  end
end
