require_relative 'use'
require_relative 'definition'
require_relative 'definition_group'

module Rbtype
  module Constants
    class Processor
      attr_reader :runtime_loader, :source, :requires, :definitions, :uses

      def initialize(runtime_loader, source)
        @runtime_loader = runtime_loader
        @source = source
        @ast = source.ast
        @requires = []
        @definitions = {}
        @uses = {}
        run
      end

      def find(path)
        @definitions[path]
      end

      def add_use(node, group)
        full_path = group.full_path
        use = Use.new(full_path, group.to_a, group.map(&:source), node)
        @uses[full_path] ||= []
        @uses[full_path] << use
      end

      def add_definition(definition)
        @definitions[definition.full_path] ||= DefinitionGroup.new(definition.full_path)
        @definitions[definition.full_path] << definition
        @runtime_loader.add_definition(definition)
      end

      def require_name(name)
        @runtime_loader.require_name(name)
      end

      def require_relative(name)
        @runtime_loader.require_relative(File.dirname(source.filename), name)
      end

      class Processor < ::AST::Processor
        class NameError < ::NameError; end

        def initialize(store)
          super()
          @store = store
          @parents = []
        end

        def process(node)
          return if node.nil?
          return node unless node.is_a?(Rbtype::AST::Node)

          on_handler = :"on_#{node.type}"
          if respond_to?(on_handler)
            send(on_handler, node)
          else
            process_all(node)
          end
        end

        def with_parent(parent)
          @parents << parent
          yield
        ensure
          @parents.pop
        end

        def parent
          @parents.last
        end

        def find_group(name)
          @store.runtime_loader.find_const_group(name)
        end

        def find_on_nesting(nestings, name)
          nestings&.each do |definition|
            group = find_group(definition.full_path.join(name))
            return group if group
          end
          find_on_constant(Constants::ConstReference.base, name)
        end

        def find_on_constant(current, path)
          wanted = current.join(path[0])
          group = find_group(wanted)
          unless group
            @store.runtime_loader.raise_with_backtrace!(Processor::NameError.new("uninitialized constant: #{wanted}"))
          end
          if path.size == 1
            group
          else
            find_on_constant(group.full_path, path[1..-1])
          end
        end

        def definition_group(node, path)
          if path.explicit_base?
            group = find_on_constant(Constants::ConstReference.base, path.without_explicit_base)
          else
            group = find_on_nesting(parent&.nesting, path[0])
            if group && path.size > 1
              group = find_on_constant(group.full_path, path[1..-1])
            end
          end
          @store.add_use(node, group) if group
          group
        end

        def backtrace_line(node)
          expr = node.location.expression
          filename = expr.source_buffer.name
          "#{filename}:#{expr.line} `#{expr.source_line.strip}`"
        end

        def on_class(node)
          @store.runtime_loader.with_backtrace(backtrace_line(node)) do
            ref = Constants::ConstReference.from_node(node.children[0])
            if ref.size > 1 && ref[0..-2] == Constants::ConstReference.base
              full_path = Constants::ConstReference.base
            else
              group = definition_group(node, ref[0..-2]) if ref.size > 1
              full_path = group&.full_path || parent&.full_path || Constants::ConstReference.base
            end
            definition = Definition.new(parent, full_path.join(ref[-1]), ref, @store.source, node)
            @store.add_definition(definition)

            with_parent(definition) do
              process_all(node)
            end
          end
        rescue Processor::NameError => e
          puts "#{e}: #{backtrace_line(node)} -- namespace may be incomplete"
        end
        alias :on_module :on_class

        def on_send(node)
          message = node.children[1]
          if [:require, :require_relative].include?(message) && parent.nil?
            args = node.children[2]
            if args.type == :str && args.children.size == 1
              filename = args.children[0]
              @store.runtime_loader.with_backtrace(backtrace_line(node)) do
                found = if message == :require
                  @store.require_name(filename)
                else
                  @store.require_relative(filename)
                end
                @store.requires << found if found
              end
            end
          end
        end
      end

      private

      def run
        Processor.new(self).process_all([@ast])
      end
    end
  end
end
