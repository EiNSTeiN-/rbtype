require 'bundler'
require 'bundler/dsl'
require 'rubygems'

module Rbtype
  module Deps
    class SpecLoader
      def initialize(spec, ignore_errors: false, cache: nil)
        @spec = spec
        @ignore_errors = ignore_errors
        @cache = cache
      end

      def sources
        [
          require_path_loaders.map(&:sources),
          source_loader&.sources,
        ].flatten
      end

      def require_path_loaders
        full_require_paths.map do |path|
          glob = "#{path}/**/*.rb"
          FileLoader.new(
            Dir[glob],
            relative_path: path,
            relative_name: short_name,
            ignore_errors: @ignore_errors,
            cache: @cache,
          )
        end
      end

      def source_loader
        return unless @spec.is_a?(Gem::Specification)
        spec_files = @spec.files.map{ |f| "#{source_pathname}/#{f}" }.select { |f| f.end_with?('.rb') }
        FileLoader.new(
          spec_files,
          relative_path: source_pathname.realpath,
          relative_name: short_name,
          ignore_errors: @ignore_errors,
          cache: @cache,
        )
      end

      def globs
        full_require_paths.map { |path| "#{path}/**/*.rb" }
      end

      def full_require_paths
        @spec.full_require_paths || []
      end

      def source_pathname
        @spec.source.expanded_original_path
      end

      def short_name
        "(#{@spec.name} @ #{@spec.version})"
      end
    end
  end
end
