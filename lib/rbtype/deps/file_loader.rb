require 'bundler'
require 'bundler/dsl'
require 'rubygems'
require 'parser/ruby24'

module Rbtype
  module Deps
    class FileLoader
      def initialize(files, relative_path:, relative_name:, ignore_errors: false, cache: nil)
        @files = files
        @relative_path = relative_path
        @relative_name = relative_name
        @ignore_errors = ignore_errors
        @cache = cache
      end

      def sources
        @sources ||= relevant_files.map { |filename| build_source(filename) }
      end

      private

      def relevant_files
        @files.select { |filename| filename.end_with?('.rb') }
      end

      def with_cache(key, modified, &block)
        return yield unless @cache
        @cache.with_cache(key, modified, &block)
      end

      def build_source(filename)
        raw_content = read_file(filename)
        modified = File.mtime(filename)
        source = with_cache("processed-source:#{filename}", modified) do
          buffer = build_buffer(raw_content, filename)
          Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24)
        end
      rescue Parser::SyntaxError
        puts "Parser error while loading #{filename}"
        raise unless @ignore_errors
      end

      def read_file(filename)
        content = File.read(filename)
        unless content.encoding == Encoding::UTF_8
          content.force_encoding(Encoding::UTF_8)
        end
        content
      end

      def build_buffer(content, filename)
        buffer = ::Parser::Source::Buffer.new(filename)
        buffer.source = content
        buffer
      end
    end
  end
end
