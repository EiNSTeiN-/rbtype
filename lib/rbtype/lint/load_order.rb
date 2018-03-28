require_relative 'base'

module Rbtype
  module Lint
    class LoadOrder < Base
      def run
        traverse_definitions do |definition|
          next unless namespaceable_definition?(definition)
          next unless definition.namespaced?

          actual_object = runtime.object_from_definition(definition)
          next unless actual_object
          resolver = Runtime::ConstantResolutionContext.new(runtime, runtime.resolve_nesting(definition.nesting[1..-1]))

          name = definition.name_ref
          path = name[0..-2]
          expected_parent = resolver.resolve(path)

          actual_full_path = actual_object.path
          conflicting_full_path = expected_parent.path.join(name[-1])

          if actual_object.parent != expected_parent
            add_error(actual_object, message: format(
              "When the runtime representation was first loaded, `%s` at %s "\
              "was defined at %s, but reloading the file would define it as "\
              "%s because %s was defined later. "\
              "This likely means this is a load-order dependant definition."\
              "To solve this issue, either avoid using a compact name altogether "\
              "or use a compact name that includes cbase (`%s` or `%s`).\n",
              snippet(definition),
              format_location(definition),
              actual_full_path,
              conflicting_full_path,
              expected_parent.path,
              actual_full_path,
              conflicting_full_path
            ))
          end
        end
      end

      private

      def namespaceable_definition?(definition)
        definition.is_a?(Lexical::ClassDefinition) ||
          definition.is_a?(Lexical::ModuleDefinition) ||
          definition.is_a?(Lexical::ConstAssignment)
      end

      def snippet(definition)
        definition.location.source_line.strip
      end
    end
  end
end
