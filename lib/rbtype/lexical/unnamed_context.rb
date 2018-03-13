module Rbtype
  module Lexical
    class UnnamedContext
      attr_reader :definitions

      def initialize(lexical_parent)
        @definitions = []
        @lexical_parent = lexical_parent
      end

      def nesting
        [self]
      end

      def inspect
        "#<#{self.class}>"
      end
    end
  end
end
