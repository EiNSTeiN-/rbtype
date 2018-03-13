require_relative 'object_space'

module Rbtype
  module Runtime
    class Undefined < ObjectSpace
      attr_reader :definitions, :name

      def initialize(definition, name)
        @definitions = [definition]
        @name = name
        super()
      end

      def type
        :undefined
      end
    end
  end
end
