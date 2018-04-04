require 'bundler'
require 'bundler/dsl'
require 'rubygems'

module Rbtype
  module Deps
    class SpecLoader
      def initialize(spec, ignore_errors: false, source_set: nil)
        @spec = spec
        @ignore_errors = ignore_errors
        @source_set = source_set
      end

      def name
        @spec.name
      end

      def sources
        @sources ||= [
          require_path_loaders.map(&:sources),
          *source_loader&.sources,
        ].flatten.compact
      end

      def require_path_loaders
        full_require_paths.map do |path|
          glob = "#{path}/**/*.rb"
          FileLoader.new(
            Dir[glob],
            ignore_errors: @ignore_errors,
            source_set: @source_set,
          )
        end
      end

      def source_loader
        return unless @spec.is_a?(Gem::Specification)
        spec_files = @spec.files.map{ |f| "#{source_pathname}/#{f}" }.select { |f| f.end_with?('.rb') }
        FileLoader.new(
          spec_files,
          ignore_errors: @ignore_errors,
          source_set: @source_set,
        )
      end

      def globs
        full_require_paths.map { |path| "#{path}/**/*.rb" }
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
    end
  end
end
