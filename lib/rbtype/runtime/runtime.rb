require_relative 'class'
require_relative 'top_level'

module Rbtype
  module Runtime
    class Runtime
      attr_reader :top_level, :delayed_definitions, :sources

      def initialize
        @top_level = TopLevel.new
        @delayed_definitions = []
        @definition_to_object = {}
        @sources = []
      end

      class DelayedDefinition
        attr_reader :parent, :definition
        def initialize(parent, definition)
          @parent = parent
          @definition = definition
        end

        def namespaced?
          [:class_definition, :module_definition, :const_assignment].include?(definition.type) &&
            definition.namespaced?
        end

        def inspect
          if definition.is_a?(Lexical::NamedContext)
            "#<#{self.class} #{definition.name_ref} on #{parent.path}>"
          else
            "#<#{self.class} #{definition}>"
          end
        end
      end

      def object_from_definition(definition)
        @definition_to_object[definition]
      end

      def self.from_sources(sources)
        runtime = new
        runtime.append_sources(sources)
        runtime
      end

      def append_sources(sources)
        sources.each do |source|
          if @sources.include?(source)
            puts "source #{source} already processed!"
          else
            @sources << source
            queue_lexical_context_definitions(source.lexical_context, @top_level)
          end
        end
        process_delayed_definitions
      end

      def queue_lexical_context_definitions(lexical_context, parent)
        lexical_context.definitions.each do |definition|
          if definition && [:class_definition, :module_definition].include?(definition.type)
            @delayed_definitions << DelayedDefinition.new(parent, definition)
          end
        end
      end

      def process_delayed_definitions
        while process_direct_definitions || process_namespaced_definition
        end
        if @delayed_definitions.any?
          puts "failed to define: #{@delayed_definitions.inspect}"
        end
      end

      def process_direct_definitions
        direct = @delayed_definitions.reject(&:namespaced?)
        direct.each do |delayed_definition|
          if process_definition(delayed_definition.parent, delayed_definition.definition)
            @delayed_definitions.delete(delayed_definition)
          else
            raise "Failed to define #{delayed_definition.inspect}"
          end
        end
        direct.any?
      end

      def process_namespaced_definition
        namespaced = @delayed_definitions.select(&:namespaced?)
        namespaced.each do |delayed_definition|
          @delayed_definitions.delete(delayed_definition)
          if process_definition(delayed_definition.parent, delayed_definition.definition)
            return true
          else
            #puts "processing #{delayed_definition.inspect} FAIL"
            @delayed_definitions << delayed_definition
          end
        end
        false
      end

      def process_definition(parent, definition)
        return true unless klass = runtime_class(definition)

        defined = define_name_on_object(klass, definition, parent)
        if defined
          #puts "processing #{definition.inspect} success"
          queue_lexical_context_definitions(definition, defined)
          true
        end
      end

      def runtime_class(definition)
        if definition.type == :class_definition
          Rbtype::Runtime::Class
        elsif definition.type == :module_definition
          Rbtype::Runtime::Module
        end
      end

      def find_const(path, object: nil)
        if !object || path.explicit_base?
          object = @top_level
          path = path.without_explicit_base
        end
        while path.size > 0
          object = object[path[0]]
          path = path[1..-1]
          break unless object
        end
        object
      end

      def resolve_nesting(nesting)
        nesting.map do |definition|
          if definition.type == :top_level
            @top_level
          else
            nesting_object = @definition_to_object[definition]
            raise RuntimeError, "Runtime object not found for #{definition}" unless nesting_object
            nesting_object
          end
        end
      end

      private

      def define_name_on_object(klass, definition, parent)
        name = definition.name_ref

        resolver = ConstantResolutionContext.new(self, resolve_nesting(definition.nesting[1..-1]))
        where = if name.size > 1
          path = name[0..-2]
          resolved = resolver.resolve(path)
          unless resolved
            if resolver.incomplete?
              puts "Could not resolve #{path}, possibly because resolution context is incomplete: #{resolver.objects}"
            end
            return
          end
          resolved
        else
          parent
        end

        expected_path = parent.path.join(name[0..-2])
        if expected_path != where.path
          if resolver.incomplete?
              puts "Expected to find #{expected_path} but instead it resolved to #{where.path} for "\
                "#{definition.location.source_buffer.name}:#{definition.location.line} "\
                "DELAYING because resolution context is yet incomplete"
            return
          end
        end

        options = {}
        if definition.type == :class_definition
          options[:superclass] = superclass_reference(resolver, where, definition)
        end

        new_object = klass.new(name[-1], parent: where, definition: definition, **options)
        #puts "define #{new_object.inspect} on #{where.inspect} as #{new_object.inspect}"
        defined = where.define(new_object)
        @definition_to_object[definition] = defined
        defined
      end

      def superclass_reference(resolver, parent, definition)
        expr = definition.superclass_expr
        if expr&.const?
          path = expr.const_reference
          superclass = resolver.resolve(path)
          superclass || Rbtype::Runtime::UnresolvedConstant.new(resolver, path, parent: parent, reference: definition)
        elsif expr
          puts "Opaque expression for superclass #{expr}"
          Rbtype::Runtime::OpaqueExpression.new(expr, parent: parent, reference: definition)
        end
      end
    end
  end
end
