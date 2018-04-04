module Rbtype
  module Deps
    class RequiredFile
      attr_reader :source, :requires, :definitions, :uses

      def initialize(runtime_loader, source)
        @runtime_loader = runtime_loader
        @source = source
        @requires = processor.requires
        @definitions = processor.definitions
        @uses = processor.uses
      end

      def inspect
        "#<#{self.class} #{source.filename}>"
      end

      private

      def processor
        @processor ||= Constants::Processor.new(@runtime_loader, source)
      end
    end
  end
end
