require_relative 'named_context'

module Rbtype
  module Lexical
    class ModuleDefinition < NamedContext
      def initialize(ast, name_ref, superclass_expr, lexical_parent)
        super(:module_definition, ast, name_ref, superclass_expr, lexical_parent)
      end
    end
  end
end
