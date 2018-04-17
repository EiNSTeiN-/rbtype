# frozen_string_literal: true
module Rbtype
  module Constants
    class Group
      include Enumerable
      attr_reader :full_path

      def initialize(full_path, definitions = nil)
        @full_path = full_path
        @definitions = [*definitions]
      end

      def name
        full_path[-1]
      end

      def to_s
        "#<#{self.class} #{full_path} (#{size} definitions)>"
      end

      def inspect
        "#<#{self.class} full_path=#{full_path} definitions=[#{@definitions.map(&:location).map(&:format).join(', ')}]>"
      end

      def [](key)
        @definitions[key]
      end

      def size
        @definitions.size
      end

      def <<(definition)
        @definitions << definition
      end

      def each(&block)
        @definitions.each(&block)
      end

      def empty?
        @definitions.empty?
      end

      def any?
        !empty?
      end

      def concat(definitions)
        @definitions.concat(definitions)
      end
    end
  end
end
