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
        full_path = if name.start_with?('/')
          name
        else
          File.expand_path("#{path}/#{name}")
        end
        find_absolute(full_path)
      end

      def find_absolute(filename)
        filename_rb = "#{filename}.rb"
        @sources.find do |source|
          source.filename == filename || source.filename == filename_rb
        end
      end

      def inspect
        "#<#{self.class} from #{path} (#{sources.size} sources)>"
      end
    end
  end
end
