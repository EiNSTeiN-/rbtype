# frozen_string_literal: true
module Rbtype
  module Deps
    class RuntimeLoader
      attr_reader :require_failed, :db
      attr_accessor :rails_autoload_locations

      class UnsupposedFileFormat < RuntimeError; end

      def initialize(source_set, require_locations, rails_autoload_locations)
        @source_set = source_set
        @require_locations = require_locations
        @rails_autoload_locations = rails_autoload_locations
        @provided = []
        @require_loop_detection = []
        @require_failed = {}
        @db_for_files = {}
        @backtrace = []
        @db = Constants::DB.new
      end

      def db_for_file(filename)
        @db_for_files[filename]
      end

      def provided(name)
        @provided << name
      end

      def build_source(filename)
        if File.extname(filename) == ".rb"
          @source_set.build_source(filename)
        else
          raise UnsupposedFileFormat, "Cannot parse #{File.extname(filename).inspect} file at #{filename}"
        end
      end

      def load_files(files)
        files.each do |filename|
          next if required_file?(filename)
          begin
            source = build_source(filename)
            load_source(source) if source
          rescue => e
            puts "#{e.class}: #{e.message}"
          end
        end
      end

      def find_source(name)
        @require_locations.each do |loc|
          filename = loc.find(name)
          return build_source(filename) if filename
        end
        nil
      end

      def find_source_absolute(base, name)
        @require_locations.each do |loc|
          expanded = File.expand_path("#{base}/#{name}")
          next unless expanded.start_with?(loc.path)
          filename = loc.find_absolute(expanded)
          return build_source(filename) if filename
        end
        nil
      end

      def find_autoloaded_source(const_ref)
        @rails_autoload_locations.each do |location|
          filename = location.find_autoloaded_file(const_ref)
          return build_source(filename) if filename
        end
        nil
      end

      def with_backtrace(line)
        @backtrace << line
        yield
      ensure
        @backtrace.pop
      end

      def raise_with_backtrace!(e)
        e.set_backtrace(@backtrace.reverse)
        raise e
      end

      def find_source!(name)
        source = find_source(name)
        raise_with_backtrace!(LoadError.new("cannot load such file -- #{name}")) unless source
        source
      end

      def define_rails_automatic_module?(name)
        @rails_autoload_locations.any? { |location| location.matching_folder?(name) }
      end

      def autoload_constant(const_ref)
        source = find_autoloaded_source(const_ref)
        if source
          load_source(source)
          @db.definitions[const_ref]
        elsif define_rails_automatic_module?(const_ref)
          @db.add_automatic_module(const_ref)
        end
      end

      def required_file?(filename)
        @db.required_files.include?(filename)
      end

      def process_requirement(req)
        unless req.filename
          puts "#{@backtrace.last}: cannot process #{req.to_s.red}"
          return
        end

        if req.method == :require
          load_from_require_locations(req)
        else
          load_from_relative_directory(req)
        end
      rescue UnsupposedFileFormat => e
        puts "#{@backtrace.last}: #{e.to_s.red}"
      end

      def load_from_require_locations(req)
        return if @provided.include?(req.filename) || @require_failed.key?(req.filename)
        source = find_source(req.filename)
        unless source
          puts "#{@backtrace.last}: cannot load such file -- #{req.filename}"
          @require_failed[req.filename] = req
          return
        end
        load_source(source)
      end

      def load_from_relative_directory(req)
        source = find_source_absolute(req.relative_directory, req.filename)
        unless source
          puts "#{@backtrace.last}: cannot load such file -- #{req.filename} relative to #{req.relative_directory}"
          return
        end
        load_source(source)
      end

      def load_sources(sources)
        sources.each do |source|
          load_source(source)
        end
      end

      def load_source(source)
        return source.filename if required_file?(source.filename)
        return source.filename if @require_loop_detection.include?(source)

        require_loop_detection(source) do
          processor = Constants::Processor.new(self, source)
          @db.merge(processor.db)
          @db.required_files << source.filename
          @db_for_files[source.filename] = processor.db
          source.filename
        end
      end

      def require_loop_detection(source)
        @require_loop_detection << source
        yield
      ensure
        @require_loop_detection.delete(source)
      end
    end
  end
end
