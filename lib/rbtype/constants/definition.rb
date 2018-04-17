# frozen_string_literal: true
module Rbtype
  module Constants
    class Definition
      attr_reader :parent_nesting, :nesting, :full_path, :path, :type, :body_node, :location

      def initialize(parent_nesting, full_path, path, type, body_node, location)
        @parent_nesting = parent_nesting.freeze
        @nesting = [self, *parent_nesting].freeze
        @full_path = full_path
        @path = path
        @type = type
        @body_node = body_node
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
        "#<#{self.class} type=#{type} full_path=#{full_path} path=#{path} nesting=[#{@nesting.map(&:full_path).map(&:to_s).join(', ')}]>"
      end
    end
  end
end
