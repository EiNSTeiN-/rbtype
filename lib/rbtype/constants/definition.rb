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
        @for_namespacing = if !@body_node
          true
        else
          body = @body_node.type == :begin ? @body_node.to_a : [@body_node]
          body.all? { |node| node.type == :class || node.type == :module }
        end
        freeze
      end

      def name
        path[-1]
      end

      def for_namespacing?
        @for_namespacing
      end

      def namespaced?
        path.size > 1
      end

      def inspect
        "#<Definition #{type} #{path}>"
      end
    end
  end
end
