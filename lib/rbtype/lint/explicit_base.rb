require_relative 'base'

module Rbtype
  module Lint
    class ExplicitBase < Base
      def run
        traverse do |group|
          group.each do |definition|
            next unless @lint_all_files || @files.include?(definition.source.filename)
            next unless definition.parent
            next unless definition.path.explicit_base?

            add_error(definition, message: format(
              "`%s` at %s "\
              "was defined with an explicit base (::). The class or module is "\
              "defined at the top level of the object hierarchy despite being located inside "\
              "another class or module.\n",
              definition.source_line,
              definition.format_location
            ))
          end
        end
      end
    end
  end
end
