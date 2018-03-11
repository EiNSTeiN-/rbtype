module Rbtype
  module Lexical
    class UnnamedContext
      attr_reader :includes, :methods, :constants, :classes, :modules

      def initialize(lexical_parent)
        @includes = []
        @methods = []
        @constants = []
        @classes = []
        @modules = []
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
