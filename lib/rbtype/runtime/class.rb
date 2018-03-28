require_relative 'named_object'

module Rbtype
  module Runtime
    class Class < NamedObject
      def initialize(name, parent:, definition:, superclass:)
        @superclass = superclass
        super(:class, name, parent: parent, definition: definition)
      end

      def superclass
        return unless @superclass
        if @superclass.type == :unresolved
          resolved = @superclass.resolved
          @superclass = resolved if resolved
        end
        @superclass
      end

      def ancestors
        [self, *superclass&.ancestors]
      end
    end
  end
end
