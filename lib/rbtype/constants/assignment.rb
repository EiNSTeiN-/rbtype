# frozen_string_literal: true
module Rbtype
  module Constants
    class Assignment
      attr_reader :parent_nesting, :full_path, :path, :expression_node, :location

      def initialize(parent_nesting, full_path, path, expression_node, location)
        @parent_nesting = parent_nesting.freeze
        @full_path = full_path
        @path = path
        @expression_node = expression_node
        @location = location
        freeze
      end

      def name
        path[-1]
      end

      def namespaced?
        path.size > 1
      end

      def to_s
        "#<#{self.class} #{type} #{path}>"
      end

      def inspect
        "#<#{self.class} full_path=#{full_path} path=#{path} parent_nesting=[#{@parent_nesting.map(&:full_path).map(&:to_s).join(', ')}]>"
      end
    end
  end
end
