require_relative 'named_context'

module Rbtype
  module Namespace
    class ClassDefinition < NamedContext
      def inspect
        "#<#{self.class.name} name=#{full_name_ref}>"
      end
    end
  end
end
