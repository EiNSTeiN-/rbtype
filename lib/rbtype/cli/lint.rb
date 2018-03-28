module Rbtype
  class CLI
    class Lint
      def initialize(runtime)
        @runtime = runtime

        @classes = [
          Rbtype::Lint::MissingDefinition.new(@runtime),
          Rbtype::Lint::LoadOrder.new(@runtime),
          Rbtype::Lint::LexicalPathMismatch.new(@runtime),
          Rbtype::Lint::NestingMismatch.new(@runtime),
        ]
      end

      def to_s
        @classes.each(&:run)
        @classes.map(&:errors).flatten.map(&:message).join("\n")
      end
    end
  end
end
