module Rbtype
  module Namespace
    class NameHierarchy
      attr_reader :children, :definitions, :references, :full_name

      def initialize(full_name)
        @children = []
        @definitions = []
        @references = Set.new
        @full_name = full_name
      end

      def append_definition(definition)
        @definitions << definition
      end

      def add_undefined(name)
        unless find(name)
          namedef = NameDefinitions.new(name, full_name.join(name))
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

      def define(name, definition: nil, reference: nil)
        namedef = find(name) || add_undefined(name)
        namedef.references << reference if reference
        namedef.append_definition(definition) if definition
        namedef
      end

      def define_recursive(path, reference: nil)
        name = path[0]
        namedef = define(name, reference: reference)
        if path.size > 1
          namedef.define_recursive(path[1..path.size])
        else
          namedef
        end
      end
    end
  end
end
