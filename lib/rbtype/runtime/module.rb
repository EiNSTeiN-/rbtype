require_relative 'named_object'

module Rbtype
  module Runtime
    class Module < NamedObject
      def initialize(name, parent:, definition:)
        super(:module, name, parent: parent, definition: definition)
      end

      def ancestors
        [self]
      end
    end
  end
end
