require_relative 'class'

module Rbtype
  module Runtime
    class Runtime
      def initialize
        @object_space = ObjectSpace.new
      end

      def self.from_sources(sources)
        runtime = new
        sources.each do |source|
          runtime.merge_lexical_context(source.lexical_context)
        end
        runtime
      end

      def merge_lexical_context(ctx, object_space: @object_space)
        ctx.definitions.each do |definition|
          case definition
          when Lexical::ClassDefinition
            name = definition.name_ref
            if name.size > 1
              obj = find_or_undefined_const(object_space, definition, definition.name_ref[0..-2])
            else
              obj = object_space
            end
            klass = Rbtype::Runtime::Class.new(definition, definition.name_ref[-1])
            obj.define(klass)
            merge_lexical_context(definition, object_space: klass)
          else
            raise RuntimeError, "not supported: #{definition.class}"
          end
        end
      end

      def find_const(path, object_space: @object_space)
        if path.explicit_base?
          object_space = @object_space
          path = path.without_explicit_base
        end
        while path.size > 0
          object_space = object_space[path[0]]
          path = path[1..-1]
          break unless object_space
        end
        object_space
      end

      private

      def find_or_undefined_const(object_space, definition, path)
        if path.explicit_base?
          object_space = @object_space
          path = path.without_explicit_base
        end
        while path.size > 0
          name = path[0]
          if object_space[name]
            object_space[name].definitions << definition
          else
            undefined = Rbtype::Runtime::Undefined.new(definition, name)
            object_space = object_space.define(undefined)
          end
          path = path[1..-1]
        end
        object_space
      end
    end
  end
end
