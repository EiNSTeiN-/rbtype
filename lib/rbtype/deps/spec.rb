# frozen_string_literal: true
require_relative 'require_location'

module Rbtype
  module Deps
    class Spec
      def initialize(spec)
        @spec = spec
      end

      def name
        @spec.name
      end

      def dependencies
        @spec.dependencies
      end

      def full_require_paths
        @spec.full_require_paths || []
      end

      def source_pathname
        @spec.full_gem_path
      end

      def short_name
        "(#{@spec.name} @ #{@spec.version})"
      end

      def require_locations
        @require_locations ||= full_require_paths.map do |path|
          files = Dir["#{path}/**/*"].select { |f| File.file?(f) }
          RequireLocation.new(path, files)
        end
      end
    end
  end
end
