require_relative 'error'

module Rbtype
  module Lint
    class Base
      attr_reader :errors

      def initialize(resolver)
        @resolver = resolver
        @errors = []
      end

      def add_error(subject, message: MSG)
        @errors << Error.new(self, subject, message)
      end

      def traverse(hierarchy = @resolver.hierarchy, &block)
        block.call(hierarchy.full_name, hierarchy.definitions, hierarchy.references)
        hierarchy.children.each do |child|
          traverse(child, &block)
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
