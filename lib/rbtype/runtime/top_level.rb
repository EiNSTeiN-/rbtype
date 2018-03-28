require_relative 'named_object'

module Rbtype
  module Runtime
    class TopLevel < ::Rbtype::Runtime::ObjectSpace
      def type
        :top_level
      end

      def ancestors
        []
      end
    end
  end
end
