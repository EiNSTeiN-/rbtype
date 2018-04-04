module Rbtype
  module Constants
    class Use
      attr_reader :full_path, :definitions, :sources, :ast

      def initialize(full_path, definitions, sources, ast)
        @full_path = full_path
        @definitions = definitions
        @sources = sources
        @ast = ast
      end

      def format_location
        "#{location.source_buffer.name}:#{location.line}"
      end

      def source_line
        location.source_line.strip
      end

      def backtrace_line
        "#{format_location} `#{source_line}`"
      end

      def location
        ast.location.expression
      end

      def inspect
        "#<Use #{@ast.type} #{full_path}>"
      end
    end
  end
end
