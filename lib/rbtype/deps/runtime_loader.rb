require_relative 'required_file'

module Rbtype
  module Deps
    class RuntimeLoader
      attr_reader :required, :require_failed, :db
      attr_accessor :rails_autoload_locations

      def initialize(require_locations, rails_autoload_locations)
        @require_locations = require_locations
        @rails_autoload_locations = rails_autoload_locations
        @provided = []
        @required = {}
        @require_loop_detection = []
        @require_failed = {}
        @backtrace = []
        @db = Constants::DB.new
      end

      def provided(name)
        @provided << name
      end

      def find_source(name)
        @require_locations.each do |loc|
          found = loc.find(name)
          return found if found
        end
        nil
      end

      def find_source_absolute(base, name)
        @require_locations.each do |loc|
          expanded = File.expand_path("#{base}/#{name}")
          next unless expanded.start_with?(loc.path)
          found = loc.find_absolute(expanded)
          return found if found
        end
        nil
      end

      def find_autoloaded_source(const_ref)
        @rails_autoload_locations.each do |location|
          source = location.find_autoloaded_file(const_ref)
          return source if source
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

      def required_source?(source)
        @required.key?(source.filename)
      end

      def process_requirement(req)
        unless req.filename
          puts "#{@backtrace.last}: cannot process #{req}"
          return
        end

        required_file = if req.method == :require
          load_from_require_locations(req)
        else
          load_from_relative_directory(req)
        end

        required_file
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
          puts "#{@backtrace.last}: cannot load such file -- #{base}/#{name}"
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
        return @required[source.filename] if required_source?(source)
        return if @require_loop_detection.include?(source)

        require_loop_detection(source) do
          required_file = RequiredFile.new(self, source)
          @db.merge(required_file.db)
          @required[source.filename] = required_file
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
