module Rbtype
  module Constants
    class Requirement
      attr_reader :node

      def initialize(node)
        @node = node
      end

      def relative_directory
        @relative_directory ||= File.dirname(node.location.expression.source_buffer.name)
      end

      def method
        node.children[1]
      end

      def argument_node
        node.children[2]
      end

      def string?
        argument_node.type == :str && argument_node.children.size == 1
      end

      def filename
        return @filename if defined?(@filename)
        @filename ||= argument_node.children[0] if string?
      end

      def source_filename
        node.location.expression.source_buffer.name
      end

      def source_line
        node.location.expression.source_line
      end

      def to_s
        "#<Require #{source_line}>"
      end
    end
  end
end
