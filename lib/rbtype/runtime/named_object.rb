require_relative 'object_space'

module Rbtype
  module Runtime
    class NamedObject < ObjectSpace
      attr_reader :type, :name

      def initialize(type, name, parent:, definition: nil, reference: nil)
        @type = type
        @name = name
        super(parent)
        self.definitions << definition if definition
        self.references << reference if reference
      end

      def path
        @path ||= parent.path.join(name)
      end

      def eql?(other)
        other.is_a?(NamedObject) &&
          other.type == type &&
          other.path == path
      end
      alias_method :==, :eql?

      def to_s
        "#{type}(#{name})"
      end

      def inspect
        "#<#{self.class} #{path}>"
      end
    end
  end
end
