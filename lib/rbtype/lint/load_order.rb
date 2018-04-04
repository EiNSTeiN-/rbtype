require_relative 'base'

module Rbtype
  module Lint
    class LoadOrder < Base
      def run
        traverse do |group|
          next unless relevant_group?(group)
          group.each do |definition|
            next unless definition.namespaced?
            next unless new_group = find_definition_group(definition.parent&.nesting, definition.path[0])
            expected_path = new_group.full_path.join(definition.path[1..-1])
            actual_path = group.full_path

            if actual_path != expected_path
              nesting = [*definition.parent&.nesting&.map(&:full_path), Constants::ConstReference.base]
              add_error(definition, message: format(
                "`%s` may be load order dependant. "\
                "One of its definitions at %s resolves a constant `%s` on the following nestings: "\
                "[%s] which initially caused this constant to be defined at `%s` but would now be defined at `%s`.\n",
                group.full_path,
                definition.format_location,
                definition.path[0],
                nesting.map(&:to_s).join(", "),
                actual_path,
                expected_path
              ))
            end
          end
        end
      end

      private

      def find_group(path)
        @runtime.find_const_group(path)
      end

      def find_on_nesting(nestings, name)
        nestings&.each do |definition|
          group = find_group(definition.full_path.join(name))
          return group if group
        end
        find_group(Constants::ConstReference.base.join(name))
      end

      def find_on_constant(current, path)
        wanted = current.join(path[0])
        group = find_group(wanted)
        return unless group
        if path.size == 1
          group
        else
          find_on_constant(group.full_path, path[1..-1])
        end
      end

      def find_definition_group(nesting, path)
        if path.explicit_base?
          find_on_constant(Constants::ConstReference.base, path.without_explicit_base)
        else
          group = find_on_nesting(nesting, path[0])
          if group && path.size > 1
            find_on_constant(group.full_path, path[1..-1])
          else
            group
          end
        end
      end

      def format_definitions(definitions)
        definitions.map do |definition|
          "#{definition.backtrace_line}#{' (for namespacing)' if definition.for_namespacing?}"
        end
      end
    end
  end
end
