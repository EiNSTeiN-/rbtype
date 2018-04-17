# frozen_string_literal: true
module Rbtype
  module Constants
    class Use
      attr_reader :full_path, :location

      def initialize(full_path, location)
        @full_path = full_path
        @location = location
      end

      def to_s
        "#<#{self.class} #{full_path}>"
      end

      def inspect
        "#<#{self.class} full_path=#{full_path} location=#{location}>"
      end
    end
  end
end
