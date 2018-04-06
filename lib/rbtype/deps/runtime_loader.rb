require_relative 'required_file'

module Rbtype
  module Deps
    class RuntimeLoader
      attr_reader :required, :definitions, :missings, :rails_automatic_modules, :rails_autoloaded_constants
      attr_accessor :rails_autoload_locations

      def initialize(require_locations, rails_autoload_locations)
        @require_locations = require_locations
        @rails_autoload_locations = rails_autoload_locations
        @provided = []
        @required = {}
        @require_loop_detection = []
        @require_failed = []
        @backtrace = []
        @definitions = {}
        @missings = {}
        @rails_automatic_modules = []
        @rails_autoloaded_constants = {}
      end

      def provided(name)
        @provided << name
      end

      def find(name)
        @require_locations.each do |loc|
          found = loc.find(name)
          return found if found
        end
        nil
      end

      def find_absolute(base, name)
        @require_locations.each do |loc|
          next unless base.start_with?(loc.path)
          found = loc.find_absolute(File.expand_path("#{base}/#{name}"))
          return found if found
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

      def find!(name)
        source = find(name)
        raise_with_backtrace!(LoadError.new("cannot load such file -- #{name}")) unless source
        source
      end

      def add_definition(definition)
        @definitions[definition.full_path] ||= Constants::DefinitionGroup.new(definition.full_path)
        @definitions[definition.full_path] << definition
      end

      def add_missing_constant(const_ref, source)
        @missings[const_ref] ||= Constants::MissingConstant.new(const_ref)
        @missings[const_ref].sources << source
      end

      def add_automatic_module(const_ref)
        @rails_automatic_modules << const_ref
        @definitions[const_ref] ||= Constants::DefinitionGroup.new(const_ref)
      end

      def find_const_group(name)
        @definitions[name]
      end

      def define_rails_automatic_module?(name)
        @rails_autoload_locations.any? { |location| location.matching_folder?(name) }
      end

      def autoload_constant(const_ref)
        source = find_autoloaded_file(const_ref)
        if source
          puts "found #{const_ref} -> #{source}"
          load_source(source)
          group = find_const_group(const_ref)
          if group
            @rails_autoloaded_constants[source.filename] = const_ref
          else
            puts "#{@backtrace.last}: loaded #{source} expecting to find #{const_ref} but that failed"
          end
          group
        elsif define_rails_automatic_module?(const_ref)
          puts "creating automatic module for #{const_ref}"
          add_automatic_module(const_ref)
        end
      end

      def find_autoloaded_file(const_ref)
        @rails_autoload_locations.each do |location|
          source = location.find_autoloaded_file(const_ref)
          return source if source
        end
        nil
      end

      def required_source?(source)
        @required.key?(source.filename)
      end

      def require_name(name)
        return if @provided.include?(name) || @require_failed.include?(name)
        source = find(name)
        unless source
          puts "#{@backtrace.last}: cannot load such file -- #{name}"
          @require_failed << name
          return
        end
        load_source(source)
      end

      def require_relative(base, name)
        source = find_absolute(base, name)
        unless source
          puts "#{@backtrace.last}: cannot load such file -- #{name}"
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
        if required_source?(source)
          @required[source.filename]
        else
          if @require_loop_detection.include?(source)
            #puts "require loop detected\n#{@backtrace.reverse}"
            #raise_with_backtrace!(LoadError.new("require loop detected"))
            return
          end
          require_loop_detection(source) do
            required_file = RequiredFile.new(self, source)
            @required[source.filename] = required_file
          end
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
