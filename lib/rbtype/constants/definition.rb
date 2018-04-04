module Rbtype
  module Constants
    class Definition
      attr_reader :parent, :full_path, :path, :source, :ast

      def initialize(parent, full_path, path, source, ast)
        @parent = parent
        @full_path = full_path
        @path = path
        @source = source
        @nesting = nesting
        @ast = ast
      end

      def name
        path[-1]
      end

      def for_namespacing?
        body = body_node
        return true unless body
        body = body.type == :begin ? body.to_a : [body]
        body.all? { |node| node.type == :class || node.type == :module }
      end

      def body_node
        if ast.type == :class
          ast.children[2]
        elsif ast.type == :module
          ast.children[1]
        end
      end

      def namespaced?
        path.size > 1
      end

      def nesting
        @nesting ||= [self, *parent&.nesting]
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
        "#<Definition #{@ast.type} #{path}>"
      end
    end
  end
end
