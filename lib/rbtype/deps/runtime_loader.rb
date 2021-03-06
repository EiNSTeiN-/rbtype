# frozen_string_literal: true
require 'active_support/inflector/methods'

module Rbtype
  module Deps
    class RuntimeLoader
      attr_reader :require_failed, :db
      attr_accessor :rails_autoload_locations
      attr_accessor :diagnostic_engine

      class UnsupposedFileFormat < RuntimeError; end

      def initialize(source_set, require_locations, rails_autoload_locations, diagnostic_engine: nil)
        @source_set = source_set
        @require_locations = require_locations
        @rails_autoload_locations = rails_autoload_locations
        @provided = []
        @require_loop_detection = []
        @require_failed = {}
        @db_for_files = {}
        @backtrace = []
        @db = Constants::DB.new
        @diagnostic_engine = diagnostic_engine
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

      def current_location
        @backtrace.last
      end

      def load_files(files)
        files.each do |filename|
          next if required_file?(filename)
          begin
            source = build_source(filename)
            load_source(source) if source
          rescue Parser::SyntaxError => e
            diag(:error, :source_processing_failed,
              "An exception occured while parsing %{filename}: %{klass}: %{message}",
              { exception: e, filename: filename, klass: e.class, message: e.message },
              current_location
            )
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

      def find_source_relative(base, name)
        expanded = File.expand_path("#{base}/#{name}")
        possible_filenames = [expanded] + RequireLocation::LOADABLE_EXTENSIONS.map { |ext| "#{expanded}#{ext}" }
        possible_filenames.each do |filename|
          return build_source(filename) if File.exist?(filename)
        end
        nil
      end

      def find_autoloaded_constant(const_ref)
        wanted = ActiveSupport::Inflector.underscore(const_ref.without_explicit_base.to_s)
        find_autoloaded_source(wanted)
      end

      def find_autoloaded_source(wanted)
        @rails_autoload_locations.each do |location|
          filename = location.find(wanted)
          return build_source(filename) if filename
        end
        nil
      end

      def with_backtrace(loc)
        raise ArgumentError, "expect #{loc} to be `Location` object" unless loc.is_a?(Constants::Location)
        @backtrace << loc
        yield
      ensure
        @backtrace.pop
      end

      def raise_with_backtrace!(e)
        e.set_backtrace(@backtrace.reverse.map(&:backtrace_line))
        raise e
      end

      def find_source!(name)
        source = find_source(name)
        raise_with_backtrace!(LoadError.new("cannot load such file -- #{name}")) unless source
        source
      end

      def define_rails_automatic_module?(name)
        path = ActiveSupport::Inflector.underscore(name.without_explicit_base.to_s)
        @rails_autoload_locations.any? { |location| location.directory_exist?(path) }
      end

      def autoload_constant(const_ref)
        source = find_autoloaded_constant(const_ref)
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

      def process_gem_requirement(filename)
        alt_filename = filename.gsub('-', '/')
        source = find_source(filename) || find_source(alt_filename)
        if source
          load_source(source)
        else
          diag(:error, :file_not_found,
            "'#{filename}' or '#{alt_filename}' were not found in any of the require paths",
            { filename: filename })
        end
      rescue UnsupposedFileFormat => e
        diag(:warning, :unsupported_file_format,
          "'#{filename}' was found but is not a loadable format",
          { filename: filename })
      end

      def process_requirement(req)
        unless req.filename
          diag(:warning, :require_unparseable,
            "Require target is not a string, and therefore cannot be loaded",
            { requirement: req },
            Constants::Location.from_node(req.argument_node)
          )
          return
        end

        case req.method
        when :require
          load_from_require_locations(req)
        when :require_dependency
          load_from_autoload_locations(req)
        when :require_relative
          load_from_relative_directory(req)
        end
      rescue UnsupposedFileFormat => e
        diag(:warning, :unsupported_file_format,
          "'#{req.filename}' was found but is not a loadable format",
          { requirement: req },
          Constants::Location.from_node(req.argument_node)
        )
      end

      def load_from_require_locations(req)
        return if @provided.include?(req.filename) || @require_failed.key?(req.filename)
        source = find_source(req.filename)
        unless source
          diag(:error, :file_not_found,
            "'#{req.filename}' was not found in any of the require paths",
            { requirement: req },
            Constants::Location.from_node(req.argument_node)
          )
          @require_failed[req.filename] = req
          return
        end
        load_source(source)
      end

      def load_from_autoload_locations(req)
        return if @provided.include?(req.filename) || @require_failed.key?(req.filename)
        source = find_autoloaded_source(req.filename)
        unless source
          diag(:error, :file_not_found,
            "'#{req.filename}' was not found in any of the autoload paths",
            { requirement: req },
            Constants::Location.from_node(req.argument_node)
          )
          @require_failed[req.filename] = req
          return
        end
        load_source(source)
      end

      def load_from_relative_directory(req)
        source = find_source_relative(req.relative_directory, req.filename)
        unless source
          diag(:error, :file_not_found,
            "'#{req.filename}' was not found relative to %{directory}",
            { requirement: req, directory: req.relative_directory },
            Constants::Location.from_node(req.argument_node)
          )
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

      def diag(level, reason, message, args, location = nil)
        return unless @diagnostic_engine
        diag = Diagnostic.new(level, reason, message, args, location)
        @diagnostic_engine.process(diag)
      end
    end
  end
end
