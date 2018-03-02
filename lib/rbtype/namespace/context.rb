module Rbtype
  module Namespace
    class Context
      include Enumerable

      attr_reader :definitions

      def initialize
        @definitions = []
      end

      def <<(definition)
        @definitions << definition
      end

      def [](key)
        @definitions[key]
      end

      def size
        @definitions.size
      end

      def each(&block)
        @definitions.each(&block)
      end
    end
  end
end
