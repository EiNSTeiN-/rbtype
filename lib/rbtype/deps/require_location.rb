# frozen_string_literal: true
require 'bundler'
require 'bundler/dsl'
require 'rubygems'

module Rbtype
  module Deps
    class RequireLocation
      attr_reader :path, :files

      def initialize(path, files)
        @path = File.expand_path(path)
        @files = Set.new(files.map{ |f| File.expand_path(f) })
      end

      def find(name)
        wanted = expand(name)
        return unless wanted.start_with?("#{path}/")
        matching = [wanted, "#{wanted}.rb", "#{wanted}.o", "#{wanted}.so", "#{wanted}.bundle", "#{wanted}.dll"]
        @files.find do |filename|
          matching.include?(filename)
        end
      end

      def directory_exist?(name)
        full_path = expand(name)
        return false unless full_path.start_with?("#{path}/")
        full_path = "#{full_path}/" unless full_path.end_with?('/')
        @files.any? do |filename|
          filename.start_with?(full_path)
        end
      end

      def to_s
        "#<#{self.class} from #{path} (#{files.size} files)>"
      end

      def inspect
        "#<#{self.class} path=#{path.inspect} files=#{files.to_a.inspect}>"
      end

      def expand(name)
        if name.start_with?('/')
          File.expand_path(name)
        elsif name.start_with?('./')
          raise ArgumentError, "Cannot process file starting with `./`, "\
            "use `File.expand_path(fname, pwd)` to get absolute path name."
        else
          File.expand_path(name, path)
        end
      end
    end
  end
end
