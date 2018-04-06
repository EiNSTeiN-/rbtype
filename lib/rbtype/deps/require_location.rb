require 'bundler'
require 'bundler/dsl'
require 'rubygems'

module Rbtype
  module Deps
    class RequireLocation
      attr_reader :path, :sources

      def initialize(path, sources)
        @path = File.expand_path(path)
        @sources = sources
      end

      def find(name)
        full_path = expand(name)
        find_absolute(full_path)
      end

      def find_absolute(filename)
        filename_rb = "#{filename}.rb"
        @sources.find do |source|
          source.filename == filename || source.filename == filename_rb
        end
      end

      def directory_exist?(name)
        full_path = expand(name)
        full_path = "#{full_path}/" unless full_path.end_with?('/')
        @sources.any? do |source|
          source.filename.start_with?(full_path)
        end
      end

      def inspect
        "#<#{self.class} from #{path} (#{sources.size} sources)>"
      end

      private

      def expand(name)
        if name.start_with?('/')
          name
        elsif name.start_with?('./')
          File.expand_path("#{Dir.pwd}/#{name}")
        else
          File.expand_path("#{path}/#{name}")
        end
      end
    end
  end
end
