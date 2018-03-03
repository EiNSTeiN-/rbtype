module Rbtype
  module Namespace
    class ConstReference
      attr_reader :parts

      def initialize(parts = nil)
        @parts = parts&.dup || []
        @explicit_base = @parts.size > 0 && @parts[0] == nil
      end

      def explicit_base?
        @explicit_base
      end

      def self.from_node(node)
        if node.type == :const
          new(parts_from_const(node))
        elsif node.type == :cbase
          new([nil])
        else
          raise ArgumentError, "cannot build name for #{node.type} node"
        end
      end

      def self.parts_from_const(node)
        return [] unless node
        if node.type == :const
          [
            *parts_from_const(node.children[0]),
            node.children[1]
          ]
        elsif node.type == :cbase
          [nil]
        else
          raise ArgumentError, "cannot process #{node.type} node"
        end
      end

      def to_s
        if @parts.size == 1 && @parts.first == nil
          '::'
        else
          @parts.join('::')
        end
      end

      def inspect
        "#<ConstReference #{to_s}>"
      end

      def ==(other)
        other.is_a?(ConstReference) && parts == other.parts
      end
      alias_method :eql?, :==

      def hash
        parts.hash
      end

      def join(other)
        other_const = wrap_array(other)

        if other_const.explicit_base?
          other_const
        else
          self.class.new([*parts, *other_const.parts])
        end
      end

      def join!(other)
        other_const = wrap_array(other)

        if other_const.explicit_base?
          @parts = other_const.parts.dup
          @explicit_base = true
        else
          @parts.push(*other_const.parts)
        end

        self
      end

      def [](index)
        if index.is_a?(Integer)
          if !in_bounds?(index)
            nil
          else
            self.class.new([parts[index]])
          end
        elsif index.is_a?(Range)
          self.class.new(parts[index])
        end
      end

      def in_bounds?(index)
        if index < 0
          parts.size >= -index
        else
          parts.size >= index + 1
        end
      end

      def size
        parts.size
      end

      def empty?
        parts.empty?
      end

      def without_explicit_base
        if explicit_base?
          self[1..-1]
        else
          self
        end
      end

      private

      def wrap_array(other)
        other_const = if other.is_a?(Array)
          self.class.new(other)
        elsif other.is_a?(Symbol)
          self.class.new([other])
        else
          other
        end
      end
    end
  end
end
