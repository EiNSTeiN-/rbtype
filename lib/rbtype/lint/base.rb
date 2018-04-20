# frozen_string_literal: true
require_relative 'error'

module Rbtype
  module Lint
    class Base
      attr_reader :errors

      def initialize(runtime, options)
        @runtime = runtime
        @constants = options[:constants]
        @files = Set.new(options[:files])
        @lint_all_files = options[:lint_all_files]
        @errors = []
      end

      private

      def namespacing_definition?(defn)
        return false unless defn.is_a?(Constants::Definition)
        if !defn.body_node
          true
        else
          body = defn.body_node.type == :begin ? defn.body_node.to_a : [defn.body_node]
          body.all? { |node| node.type == :class || node.type == :module }
        end
      end

      def relevant_group?(group)
        @lint_all_files ||
          @constants.include?(group.full_path) ||
          group.to_a.any? { |definition| !namespacing_definition?(definition) && @files.include?(definition.location.filename) }
      end

      def relevant_filename?(filename)
        @lint_all_files || @files.include?(filename)
      end

      def sources
        @runtime.sources
      end

      def runtime
        @runtime
      end

      def add_error(subject, message: MSG)
        @errors << Error.new(self, subject, message)
      end

      def traverse(&block)
        @runtime.db.definitions.each do |_, child|
          block.call(child)
        end
      end

      def format_list(list)
        [
          "- ",
          list.join("\n- ")
        ].join
      end
    end
  end
end
