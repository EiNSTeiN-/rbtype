require_relative '../base'
require 'active_support/inflector/methods'

module Rbtype
  module Lint
    module Rails
      class RequireAutoloadableFile < Base
        def run
          @files.each do |filename|
            required_file = @runtime.required[filename]
            required_file.requires.each do |target|
              loc = find_autoload_location(target.source.filename)
              if loc
                add_error(filename, message: format(
                  "In %s a require statement loads %s which appears in a Rails autoload path under %s. "\
                  "Using `require` causes problems with autoloading, `require_dependency` should be used instead. "\
                  "See http://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoloading-and-require for more details.\n",
                  filename,
                  target.source.filename,
                  loc.path
                ))
              end
            end
          end
        end

        private

        def find_autoload_location(filename)
          @runtime.rails_autoload_locations.find do |loc|
            loc.sources.any? { |source| source.filename == filename }
          end
        end
      end
    end
  end
end
