require_relative 'object_space'

module Rbtype
  module Runtime
    class Class < ObjectSpace
      attr_reader :definitions, :name

      def initialize(definition, name)
        @definitions = [definition]
        @name = name
        super()
      end

      def type
        :class
      end
    end
  end
end
