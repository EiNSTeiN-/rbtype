require_relative 'name_hierarchy'

module Rbtype
  module Namespace
    class NameDefinitions < NameHierarchy
      attr_reader :name

      def initialize(name)
        super()
        @name = name
      end
    end
  end
end
