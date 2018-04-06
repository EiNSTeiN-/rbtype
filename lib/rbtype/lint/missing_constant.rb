require_relative 'base'

module Rbtype
  module Lint
    class MissingConstant < Base
      def run
        @runtime.missings.each do |_, missing_constant|
          group = @runtime.find_const_group(missing_constant.full_path)
          next unless group
          add_error(group.first, message: format(
            "`%s` could not be resolved when file %s "\
            "was initially loaded, but the constant was later defined at %s. "\
            "This can be resolved by adding a `require` statement in the first file or "\
            "avoid the use of compact name to define classes.\n",
            missing_constant.full_path,
            missing_constant.sources.first.filename,
            group.first.format_location
          ))
        end
      end
    end
  end
end
