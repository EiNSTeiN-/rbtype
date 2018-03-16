require_relative 'class'

module Rbtype
  module Runtime
    class Runtime
      def initialize
        @object_space = ObjectSpace.new
        @definition_to_object = {}
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
            klass = Rbtype::Runtime::Class.new(definition, definition.name_ref[-1], obj)
            puts "defined #{name} as #{klass.inspect} on #{obj.inspect}"
            @definition_to_object[definition] = klass
            merge_lexical_context(definition, object_space: klass)
          when Lexical::ModuleDefinition
            name = definition.name_ref
            if name.size > 1
              obj = find_or_undefined_const(object_space, definition, definition.name_ref[0..-2])
            else
              obj = object_space
            end
            mod = Rbtype::Runtime::Module.new(definition, definition.name_ref[-1], obj)
            @definition_to_object[definition] = mod
            merge_lexical_context(definition, object_space: mod)
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

      def names
        @object_space.names
      end

      private

      def find_or_undefined_const(object_space, definition, path)
        if path.explicit_base?
          object_space = @object_space
          path = path.without_explicit_base
        end
        while path.size > 0
          name = path[0]
          object = object_space[name] || resolve_const(definition.nesting[1..-1], name)
          puts "resolved #{name} as #{object.inspect} on #{object_space.inspect}"
          if object
            object.definitions << definition
            object_space = object
          else
            undefined = Rbtype::Runtime::Undefined.new(definition, name)
            object_space = object_space.define(undefined)
          end
          path = path[1..-1]
        end
        object_space
      end

      def resolve_const(nesting, name)
        puts "nesting #{nesting} for #{name}"
        nesting.each do |definition|
          object = if definition.instance_of?(Rbtype::Lexical::UnnamedContext)
            @object_space[name]
          else
            nesting_object = @definition_to_object[definition]
            raise RuntimeError, 'nesting should be known here' unless nesting_object
            nesting_object[name]
          end
          return object if object
        end
        nil
      end
    end
  end
end
