module Rbtype
  module Lexical
    class UnnamedContext
      attr_reader :type, :definitions

      def initialize(type, lexical_parent)
        @type = type
        @definitions = []
        @lexical_parent = lexical_parent
      end

      def nesting
        @nesting ||= [self]
      end

      def inspect
        "#<#{self.class}>"
      end
    end
  end
end
