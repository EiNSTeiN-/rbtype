module Rbtype
  module Namespace
    class NameHierarchy
      attr_reader :children, :definitions

      def initialize
        @children = []
        @definitions = []
      end

      def append_definition(definition)
        @definitions << definition
      end

      def add_undefined(name)
        unless find(name)
          namedef = NameDefinitions.new(name)
          @children << namedef
          namedef
        end
      end

      def find(wanted)
        @children.find { |namedef| namedef.name == wanted }
      end

      def find_recursive(path)
        name = path[0]
        namedef = find(name)
        return unless namedef
        if path.size > 1
          namedef.find_recursive(path[1..path.size])
        else
          namedef
        end
      end

      def define(name, definition = nil)
        namedef = find(name) || add_undefined(name)
        namedef.append_definition(definition) if definition
        namedef
      end

      def define_recursive(path)
        name = path[0]
        namedef = define(name)
        if path.size > 1
          namedef.define_recursive(path[1..path.size])
        else
          namedef
        end
      end
    end
  end
end
