require_relative 'required_file'

module Rbtype
  module Deps
    class RuntimeLoader
      attr_reader :definitions

      def initialize(require_locations)
        @require_locations = require_locations
        @provided = []
        @required = {}
        @require_loop_detection = []
        @require_failed = []
        @backtrace = []
        @definitions = {}
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

      def find_const_group(name)
        @definitions[name]
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
