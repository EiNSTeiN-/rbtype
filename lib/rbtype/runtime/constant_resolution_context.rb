module Rbtype
  module Runtime
    class ConstantResolutionContext
      attr_reader :nesting

      def initialize(runtime, nesting)
        @runtime = runtime
        @nesting = nesting
        @cache = {}
      end

      def objects
        nesting + nesting.first.ancestors
      end

      def objects_hash
        objects.hash
      end

      def current_cache
        @cache[objects_hash] ||= {}
      end

      def resolve(path)
        if !path.is_a?(Lexical::ConstReference) || path.size < 1
          raise ArgumentError, 'argument must be a const reference'
        end

        cache = current_cache
        if cache.key?(path)
          cache[path]
        end

        if path.explicit_base?
          object = @runtime.top_level
          search_path = path.without_explicit_base
        else
          object = resolve_name_with(path[0], objects: objects)
          return unless object
          search_path = path[1..-1]
        end

        if search_path.size > 0
          cache[path] = resolve_recursively_on(object, search_path)
        else
          cache[path] = object
        end
      end

      def incomplete?
        objects.last.is_a?(Rbtype::Runtime::UnresolvedConstant) ||
          objects.last.is_a?(Rbtype::Runtime::OpaqueExpression)
      end

      def inspect
        "#<#{self.class} #{objects}>"
      end

      private

      def resolve_recursively_on(parent, path)
        name = path[0]
        object = parent[name]
        return unless object
        if path.size > 1
          resolve_recursively_on(object, path[1..-1])
        else
          object
        end
      end

      def resolve_name_with(name, objects:)
        parent = objects.find { |object| object[name] }
        parent[name] if parent
      end
    end
  end
end
