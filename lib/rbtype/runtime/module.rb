require_relative 'object_space'

module Rbtype
  module Runtime
    class Module < ObjectSpace
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
        :module
      end

      def to_s
        "#{type}(#{name})"
      end

      def inspect
        "#<#{self.class} #{path}>"
      end
    end
  end
end
