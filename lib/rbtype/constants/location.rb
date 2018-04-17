# frozen_string_literal: true
module Rbtype
  module Constants
    class Location
      attr_reader :filename, :line, :source_line

      def initialize(filename, line, source_line)
        @filename = filename
        @line = line
        @source_line = source_line
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
        expr_loc = node.location.expression
        new(expr_loc.source_buffer.name, expr_loc.line, expr_loc.source_line.strip)
      end
    end
  end
end
