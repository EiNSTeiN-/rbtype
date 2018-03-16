require_relative 'object_space'

module Rbtype
  module Runtime
    class Class < ObjectSpace
      attr_reader :definitions, :name

      def initialize(definition, name, parent)
        @definitions = [definition]
        @name = name
        super(parent)
      end

      def path
        @path ||= parent.path.join(name)
      end

      def type
        :class
      end

      def to_s
        "class(#{name})"
      end

      def inspect
        "#<#{self.class.name} #{path}>"
      end
    end
  end
end
