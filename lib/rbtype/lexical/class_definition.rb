require_relative 'named_context'

module Rbtype
  module Lexical
    class ClassDefinition < NamedContext
      def initialize(ast, name_ref, superclass_expr, lexical_parent)
        super(:class_definition, ast, name_ref, superclass_expr, lexical_parent)
      end

      def inspect
        "#<#{self.class.name} name=#{name_ref}>"
      end
    end
  end
end
