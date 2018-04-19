# frozen_string_literal: true
module Rbtype
  module Constants
    class DB
      attr_reader :required_files, :requires, :definitions, :uses, :missings
      attr_reader :automatic_modules

      def initialize(parent = nil)
        @parent = parent
        @required_files = []
        @requires = []
        @definitions = {}
        @uses = {}
        @missings = {}
        @automatic_modules = []
      end

      def add_use(use)
        @parent&.add_use(use)
        @uses[use.full_path] ||= Group.new(use.full_path)
        @uses[use.full_path] << use
      end

      def add_definition(definition)
        @parent&.add_definition(definition)
        path = definition.full_path
        @definitions[path] ||= Group.new(path)
        @definitions[path] << definition
      end

      def add_automatic_module(const_ref)
        @parent&.add_automatic_module(const_ref)
        @automatic_modules << const_ref
        @definitions[const_ref] ||= Group.new(const_ref)
      end

      def add_missing_constant(missing_constant)
        @parent&.add_missing_constant(missing_constant)
        path = missing_constant.full_path
        @missings[path] ||= Group.new(path)
        @missings[path] << missing_constant
      end

      def add_require(req)
        @parent&.add_require(req)
        @requires << req
      end

      def merge(other)
        @requires.concat(other.requires.dup)
        merge_group(@definitions, other.definitions)
        merge_group(@uses, other.uses)
        merge_group(@missings, other.missings)
        @automatic_modules.concat(other.automatic_modules.dup)
        self
      end

      private

      def merge_group(this, other)
        other.each do |key, group|
          this[key] ||= Group.new(group.full_path)
          this[key].concat(group.to_a)
        end
      end
    end
  end
end
