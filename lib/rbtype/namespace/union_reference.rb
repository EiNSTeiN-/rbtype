module Rbtype
  module Namespace
    class UnionReference
      attr_reader :members

      def initialize(members)
        @members = members
      end

      def to_s
        "union_of(#{members.map(&:to_s).join(' | ')})"
      end

      def ==(other)
        other.is_a?(UnionReference) &&
          other.members == members
      end
    end
  end
end
