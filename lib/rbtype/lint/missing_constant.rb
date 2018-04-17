# frozen_string_literal: true
require_relative 'base'

module Rbtype
  module Lint
    class MissingConstant < Base
      def run
        @runtime.db.missings.each do |_, missings|
          missings.each do |missing_constant|
            group = @runtime.db.definitions[missing_constant.full_path]
            next unless group
            add_error(group.first, message: format(
              "`%s` could not be resolved when file %s "\
              "was initially loaded, but the constant was later defined at %s. "\
              "This can be resolved by adding a `require` statement in the first file or "\
              "avoid the use of compact name to define classes.\n",
              missing_constant.full_path,
              missing_constant.location.filename,
              group.first.location.format
            ))
          end
        end
      end
    end
  end
end
