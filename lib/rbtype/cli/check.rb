module Rbtype
  class CLI
    class Check
      class Error
        attr_reader :message

        def initialize(message)
          @message = message
        end
      end

      def initialize(resolver)
        @resolver = resolver
        @errors = []

        process_hierarchy(@resolver.hierarchy)
      end

      def add_error(message)
        @errors << Error.new(message)
      end

      def process_hierarchy(hierarchy)
        hierarchy.definitions do |definition|
          process_definition(definition)
        end
        hierarchy.children do |child|
          process_hierarchy(child)
        end
      end
    end
  end
end
