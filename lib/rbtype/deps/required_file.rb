module Rbtype
  module Deps
    class RequiredFile
      attr_reader :source, :db

      def initialize(runtime_loader, source)
        @runtime_loader = runtime_loader
        @source = source
        @db = processor.db
      end

      def inspect
        "#<#{self.class} #{@source.filename}>"
      end

      private

      def processor
        @processor ||= Constants::Processor.new(@runtime_loader, @source)
      end
    end
  end
end
