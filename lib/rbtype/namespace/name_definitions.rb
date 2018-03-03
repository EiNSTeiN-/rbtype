require_relative 'name_hierarchy'

module Rbtype
  module Namespace
    class NameDefinitions < NameHierarchy
      attr_reader :name

      def initialize(name, full_name)
        super(full_name)
        @name = name
      end
    end
  end
end
