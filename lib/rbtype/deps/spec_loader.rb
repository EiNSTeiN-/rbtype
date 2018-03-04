require 'bundler'
require 'bundler/dsl'
require 'rubygems'

module Rbtype
  module Deps
    class SpecLoader
      def initialize(resolver, spec)
        @resolver = resolver
        @spec = spec
      end

      def load_all
        require_path_loaders.each(&:load_all)
        source_loader&.load_all
      end

      def require_path_loaders
        full_require_paths.map do |path|
          glob = "#{path}/**/*.rb"
          FileLoader.new(
            @resolver,
            Dir[glob],
            relative_path: path,
            relative_name: short_name,
            ignore_errors: true
          )
        end
      end

      def source_loader
        return unless @spec.is_a?(Gem::Specification)
        spec_files = @spec.files.map{ |f| "#{source_pathname}/#{f}" }.select { |f| f.end_with?('.rb') }
        FileLoader.new(
          @resolver,
          spec_files,
          relative_path: source_pathname.realpath,
          relative_name: short_name,
          ignore_errors: true
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
