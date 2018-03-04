module Rbtype
  class CLI
    class Describe
      def initialize(resolver, ref)
        @resolver = resolver
        @ref = ref
      end

      def to_s
        out = [definitions_descriptions]

        if definitions
          out << definitions_agreement if definitions.size > 1
          out << inheritance_info if class_definition?
        end

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

      def definitions_agree?
        definitions.map(&:class).uniq.size == 1
      end

      def class_definition?
        definitions_agree? && definitions.first.is_a?(Namespace::ClassDefinition)
      end

      def definitions_agreement
        if definitions_agree?
          name = friendly_name(definitions.first)
          "All definitions agree `#{@ref}` is a #{name}"
        else
          possibilities = definitions.uniq(&:class)
          names = possibilities.map { |p| friendly_name(p) }
          "#{'W'.yellow}: Possible runtime error, `#{@ref}` may be (#{names.join(' | ')})"
        end
      end

      def inheritance_info
        superclasses = definitions.map { |defn| defn.superclass_expr&.const_reference }.uniq
        if superclasses.size == 1
          superclass = superclasses.first
          if superclass == nil
            "All definitions agree `#{@ref}` does not inherit from a parent"
          else
            "All definitions agree `#{@ref}` inherits from `#{superclasses.first}`"
          end
        else
          names = superclasses.map { |s| s&.to_s || 'nothing' }.join(' | ')
          "#{'W'.yellow}: Possible runtime error, `#{@ref}` superclasses mismatch (#{names})"
        end
      end

      def friendly_name(definition)
        case definition
        when Namespace::ModuleDefinition
          'module'
        when Namespace::ClassDefinition
          'class'
        when Namespace::ConstDefinition
          'constant'
        when Namespace::MethodDefinition
          'method'
        when nil
          'nil'
        else
          "#<#{definition.class}>"
        end
      end

      def description(definition)
        loc = definition.location
        "a #{friendly_name(definition)} at #{loc.source_buffer.name}:#{loc.line}"
      end

      def definitions
        @definitions ||= @resolver.resolve_definitions(@ref)
      end
    end
  end
end
