require_relative 'named_object'

module Rbtype
  module Runtime
    class UnresolvedConstant < NamedObject
      attr_reader :resolver

      def initialize(resolver, name, parent:, reference:)
        @resolver = resolver
        super(:unresolved, name, parent: parent, reference: reference)
      end

      def ancestors
        if resolved
          @resolved.ancestors
        else
          [self]
        end
      end

      def resolved
        @resolved ||= resolver.resolve(name)
      end
    end
  end
end
