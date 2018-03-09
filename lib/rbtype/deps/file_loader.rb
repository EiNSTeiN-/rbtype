require 'bundler'
require 'bundler/dsl'
require 'rubygems'
require 'parser/ruby24'

module Rbtype
  module Deps
    class FileLoader
      def initialize(resolver, files, relative_path:, relative_name:, ignore_errors: false)
        @resolver = resolver
        @files = files
        @relative_path = relative_path
        @relative_name = relative_name
        @ignore_errors = ignore_errors
      end

      def load_all
        @files.each do |filename|
          source = build_source(filename)
          next if source.buffer.source.empty?
          if source.ast
            @resolver.process_from_root(source.ast)
          else
            raise RuntimeError, "failed to parse #{filename}" unless @ignore_errors
          end
        end
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
        buffer = ::Parser::Source::Buffer.new("#{@relative_name}/#{relative_filename(filename)}")
        buffer.source = content
        buffer
      end

      def relative_filename(filename)
        filename.sub("#{@relative_path}/", '')
      end
    end
  end
end
