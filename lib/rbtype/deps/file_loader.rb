require 'bundler'
require 'bundler/dsl'
require 'rubygems'
require 'parser/ruby24'

module Rbtype
  module Deps
    class FileLoader
      def initialize(files, relative_path:, relative_name:, ignore_errors: false)
        @files = files
        @relative_path = relative_path
        @relative_name = relative_name
        @ignore_errors = ignore_errors
      end

      def sources
        @sources ||= @files.map { |filename| build_source(filename) }
      end

      private

      def build_source(filename)
        buffer = build_buffer(read_file(filename), filename)
        Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24)
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
