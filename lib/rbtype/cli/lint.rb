module Rbtype
  class CLI
    class Lint
      def initialize(resolver)
        @resolver = resolver

        @classes = [
          Rbtype::Lint::ConflictingDefinition.new(@resolver),
          Rbtype::Lint::MissingDefinition.new(@resolver),
          #Rbtype::Lint::UnresolvedReference.new(@resolver),
        ]
      end

      def to_s
        @classes.each(&:run)
        @classes.map(&:errors).flatten.map(&:message).join("\n")
      end
    end
  end
end
