require 'rubygems'
require 'bundler'
require 'bundler/dsl'
require 'rubygems'
require 'parser/ruby24'

module Rbtype
  module Deps
    class FileLoader
      def initialize(files, ignore_errors: false, source_set: nil)
        @files = files
        @ignore_errors = ignore_errors
        @source_set = source_set
      end

      def sources
        @sources ||= relevant_files.map { |filename| load_source(filename) }
      end

      private

      def relevant_files
        @files.select { |filename| filename.end_with?('.rb') && File.exist?(filename) }
      end

      def load_source(filename)
        @source_set.load_source(filename)
      rescue Parser::SyntaxError
        puts "Parser error while loading #{filename}"
        raise unless @ignore_errors
      end
    end
  end
end
