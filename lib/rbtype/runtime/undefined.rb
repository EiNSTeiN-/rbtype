require_relative 'named_object'

module Rbtype
  module Runtime
    class Undefined < NamedObject
      def initialize(name, parent:, reference:)
        super(:undefined, name, parent: parent, reference: reference)
      end
    end
  end
end
