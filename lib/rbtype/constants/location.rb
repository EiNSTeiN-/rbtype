# frozen_string_literal: true
module Rbtype
  module Constants
    class Location
      attr_reader :filename, :line, :source_line, :source_range

      def initialize(source_range)
        @source_range = source_range
        @filename = source_range.source_buffer.name
        @line = source_range.line
        @source_line = source_range.source_line.strip
        freeze
      end

      def format
        "#{filename}:#{line}"
      end

      def backtrace_line
        "#{filename}:#{line} `#{source_line}`"
      end

      def to_s
        "at #{backtrace_line}"
      end

      def inspect
        "#<#{self.class} filename=#{filename.inspect} line=#{line} source_line=#{source_line.inspect}>"
      end

      def self.from_node(node)
        return unless node
        new(node.location.expression)
      end
    end
  end
end
