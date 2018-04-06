module Rbtype
  class CLI
    class Lint
      def initialize(runtime, **options)
        @runtime = runtime

        @classes = [
          Rbtype::Lint::LexicalPathMismatch.new(@runtime, **options),
          Rbtype::Lint::ExplicitBase.new(@runtime, **options),
          #Rbtype::Lint::MultipleDefinitions.new(@runtime, **options),
          Rbtype::Lint::LoadOrder.new(@runtime, **options),
          Rbtype::Lint::MissingConstant.new(@runtime, **options),
          Rbtype::Lint::Rails::AutoloadConstants.new(@runtime, **options),
          Rbtype::Lint::Rails::RequireAutoloadableFile.new(@runtime, **options),
        ]
      end

      def to_s
        @classes.each(&:run)
        @classes.map(&:errors).flatten.map(&:message).join("\n")
      end
    end
  end
end
