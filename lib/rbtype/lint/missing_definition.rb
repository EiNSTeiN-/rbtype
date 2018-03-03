require_relative 'base'

module Rbtype
  module Lint
    class MissingDefinition < Base
      def run
        traverse do |name, definitions, references|
          next if name == Namespace::ConstReference.new([nil])
          next unless definitions.size == 0
          add_error(name, message: format("Missing definition for %s\n%s\n",
            name, format_references_list(references)))
        end
      end

      def format_references_list(references)
        format_list(references.map { |ref| "in definition of #{ref.full_name_ref} at #{format_location(ref)}" })
      end
    end
  end
end
