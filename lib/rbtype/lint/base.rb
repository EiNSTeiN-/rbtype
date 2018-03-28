require_relative 'error'

module Rbtype
  module Lint
    class Base
      attr_reader :errors

      def initialize(runtime)
        @runtime = runtime
        @errors = []
      end

      private

      def sources
        @runtime.sources
      end

      def runtime
        @runtime
      end

      def add_error(subject, message: MSG)
        @errors << Error.new(self, subject, message)
      end

      def traverse(object = @runtime.top_level, &block)
        block.call(object)
        object.each do |_, child|
          traverse(child, &block)
        end
      end

      def traverse_definitions(&block)
        sources.each do |source|
          traverse_lexical_context_definitions(source.lexical_context, &block)
        end
      end

      def traverse_lexical_context_definitions(context, &block)
        block.call(context)
        if context.respond_to?(:definitions)
          context.definitions.each do |subcontext|
            traverse_lexical_context_definitions(subcontext, &block)
          end
        end
      end

      def format_list(list)
        [
          "- ",
          list.join("\n- ")
        ].join
      end

      def format_location(definition)
        loc = definition.location
        "#{loc.source_buffer.name}:#{loc.line}"
      end
    end
  end
end
