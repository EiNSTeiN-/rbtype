module Rbtype
  module Namespace
    class InstanceReference
      attr_reader :type_const

      def initialize(type_const)
        @type_const = type_const
      end

      def to_s
        "instance_of(#{@type_const})"
      end

      def ==(other)
        other.is_a?(InstanceReference) &&
          other.type_const == type_const
      end
    end
  end
end
