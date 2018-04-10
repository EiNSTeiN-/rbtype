module Rbtype
  module Constants
    class MissingConstant
      attr_reader :full_path, :node

      def initialize(full_path, node)
        @full_path = full_path
        @node = node
      end

      def name
        full_path[-1]
      end

      def source_filename
        node.location.expression.source_buffer.name
      end

      def to_s
        "#<MissingConstant #{full_path}>"
      end

      def inspect
        "#<MissingConstant full_path=#{full_path} source_filename=#{source_filename}>"
      end
    end
  end
end
