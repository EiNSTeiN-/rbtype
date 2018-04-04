module Rbtype
  module Constants
    class DefinitionGroup
      include Enumerable
      attr_reader :full_path

      def initialize(full_path, definitions = nil)
        @full_path = full_path
        @definitions = definitions || []
      end

      def name
        full_path[-1]
      end

      def inspect
        "#<DefinitionGroup #{full_path}>"
      end

      def [](key)
        @definitions[key]
      end

      def size
        @definitions.size
      end

      def <<(definition)
        @definitions << definition
      end

      def each(&block)
        @definitions.each(&block)
      end

      def empty?
        @definitions.empty?
      end

      def any?
        !empty?
      end
    end
  end
end
