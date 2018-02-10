module Rbtype
  module Type
    class NativeType
      def initialize(klass_name)
        @klass_name = klass_name
      end

      def type?(klass_name)
        klass_name == @klass_name
      end

      def ==(other)
        other.is_a?(self.class) &&
          other.type?(@klass_name)
      end
    end
  end
end
