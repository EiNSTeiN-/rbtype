# frozen_string_literal: true
require 'rbtype/processors/require_location_finder'

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

      def simplify_to_string
        node = Rbtype::AST::Processor.new([Processors::RequireLocationFinder.new]).process(argument_node)
        node.children[0] if node && node.type == :str
      end

      def filename
        return @filename if defined?(@filename)
        @filename = if string?
          argument_node.children[0]
        else
          simplify_to_string
        end
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
