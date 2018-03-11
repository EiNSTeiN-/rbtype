require_relative 'named_context'

module Rbtype
  module Lexical
    class ClassDefinition < NamedContext
      def inspect
        "#<#{self.class.name} name=#{name_ref}>"
      end
    end
  end
end
