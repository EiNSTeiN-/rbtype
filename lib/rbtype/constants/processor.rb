# frozen_string_literal: true
require_relative 'use'
require_relative 'definition'
require_relative 'group'
require_relative 'missing_constant'
require_relative 'db'

module Rbtype
  module Constants
    class Processor
      attr_reader :source, :db

      class NameError < ::NameError; end

      def initialize(runtime_loader, source)
        @runtime_loader = runtime_loader
        @parents = []
        @source = source
        @db = DB.new(@runtime_loader.db)
        process_body(source.ast)
      end

      private

      def processable_node?(node)
        node.is_a?(::AST::Node) &&
          [:send, :class, :module, :casgn].include?(node.type)
      end

      def process_body(node)
        return unless node.is_a?(::AST::Node)
        if node.type == :begin
          process_all(node)
        elsif processable_node?(node)
          process(node)
        end
      end

      def process_all(node)
        node.to_a.each do |child|
          process(child) if processable_node?(child)
        end
      end

      def process(node)
        @runtime_loader.with_backtrace(Location.from_node(node)) do
          case node.type
          when :send
            on_send(node)
          when :class, :module
            on_module(node)
          when :casgn
            on_casgn(node)
          end
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
        @db.definitions[name] ||
          @runtime_loader.db.definitions[name] ||
          @runtime_loader.autoload_constant(name)
      end

      def find_on_nesting(node, nestings, name)
        nestings&.each do |definition|
          maybe_const = definition.full_path.join(name)
          group = find_group(maybe_const)
          if group
            return group
          else
            @db.add_missing_constant(MissingConstant.new(maybe_const, Location.from_node(node)))
          end
        end
        group = find_absolute_constant(node, Constants::ConstReference.base, name)
        @db.add_missing_constant(MissingConstant.new(maybe_const, Location.from_node(node))) unless group
        group
      end

      def find_absolute_constant(node, current, path)
        wanted = current.join(path[0])
        group = find_group(wanted)
        unless group
          @db.add_missing_constant(MissingConstant.new(wanted, Location.from_node(node)))
          @runtime_loader.raise_with_backtrace!(Processor::NameError.new("uninitialized constant: #{wanted}"))
        end
        if path.size == 1
          group
        else
          find_absolute_constant(node, group.full_path, path[1..-1])
        end
      end

      def definition_group(node, path)
        if path.explicit_base?
          group = find_absolute_constant(node, Constants::ConstReference.base, path.without_explicit_base)
        else
          group = find_on_nesting(node, parent&.nesting, path[0])
          if group && path.size > 1
            group = find_absolute_constant(node, group.full_path, path[1..-1])
          end
        end
        if group
          @db.add_use(Use.new(group.full_path, Location.from_node(node)))
        end
        group
      end

      def backtrace_line(node)
        expr = node.location.expression
        filename = expr.source_buffer.name
        "#{filename}:#{expr.line} `#{expr.source_line.strip}`"
      end

      def on_module(node)
        ref = Constants::ConstReference.from_node(node.children[0])
        if ref.size > 1 && ref[0..-2] == Constants::ConstReference.base
          full_path = Constants::ConstReference.base
        else
          group = definition_group(node, ref[0..-2]) if ref.size > 1
          full_path = group&.full_path || parent&.full_path || Constants::ConstReference.base
        end
        definition = Definition.new(
          parent&.nesting,
          full_path.join(ref[-1]),
          ref,
          node.type,
          node.type == :module ? node.children[1] : node.children[2],
          Location.from_node(node),
        )
        @db.add_definition(definition)

        with_parent(definition) do
          body = node.type == :module ? node.children[1] : node.children[2]
          process_body(body) if body
        end
      rescue Processor::NameError => e
        @runtime_loader.diag(:warning, :uninitialized_constant,
          "Namespace may be incomplete: %{message}",
          { exception: e, klass: e.class, message: e.message },
          Location.from_node(node.children[0])
        )
      end

      def on_casgn(node)
        base = Constants::ConstReference.from_node(node.children[0]) if node.children[0]
        name = Constants::ConstReference.new([node.children[1]])
        if base && base == Constants::ConstReference.base
          full_path = Constants::ConstReference.base
        else
          group = definition_group(node, base) if base
          full_path = group&.full_path || parent&.full_path || Constants::ConstReference.base
        end
        assignment = Assignment.new(
          parent&.nesting,
          full_path.join(name),
          base ? base.join(name) : name,
          node.children[2],
          Location.from_node(node),
        )
        @db.add_definition(assignment)

        #with_parent(definition) do
        #  body = node.type == :module ? node.children[1] : node.children[2]
        #  process_body(body) if body
        #end
      rescue Processor::NameError => e
        @runtime_loader.diag(:warning, :uninitialized_constant,
          "Namespace may be incomplete: %{message}",
          { exception: e, klass: e.class, message: e.message },
          Location.from_node(node.children[0])
        )
      end

      def on_send(node)
        receiver = node.children[0]
        message = node.children[1]
        return unless [:require, :require_relative, :require_dependency].include?(message) && receiver.nil?
        req = Requirement.new(node)
        @db.add_require(req)
        resolved_filename = @runtime_loader.process_requirement(req)
        req.resolved_filename = resolved_filename
      end
    end
  end
end
