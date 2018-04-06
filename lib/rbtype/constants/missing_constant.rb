module Rbtype
  module Constants
    class MissingConstant
      include Enumerable
      attr_reader :full_path, :sources

      def initialize(full_path)
        @full_path = full_path
        @sources = []
      end

      def name
        full_path[-1]
      end

      def to_s
        "#<MissingConstant #{full_path}>"
      end
      alias :inspect :to_s
    end
  end
end
