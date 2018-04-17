# frozen_string_literal: true
module Rbtype
  module Constants
    class Requirement
      attr_accessor :resolved_filename

      def initialize(node)
        @node = node
        @resolved_filename = nil
      end

      def location
        @location ||= Location.from_node(@node)
      end

      def relative_directory
        @relative_directory ||= File.dirname(@node.location.expression.source_buffer.name)
      end

      def method
        @node.children[1]
      end

      def argument_node
        @node.children[2]
      end

      def string?
        argument_node.type == :str && argument_node.children.size == 1
      end

      def filename
        return @filename if defined?(@filename)
        @filename ||= argument_node.children[0] if string?
      end

      def to_s
        "#<#{self.class} #{location.source_line}>"
      end

      def inspect
        "#<#{self.class} location=#{location.inspect} resolved_filename=#{resolved_filename.inspect}>"
      end
    end
  end
end
