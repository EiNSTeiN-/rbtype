# frozen_string_literal: true
require_relative '../base'
require 'active_support/inflector/methods'

module Rbtype
  module Lint
    module Rails
      class RequireAutoloadableFile < Base
        def run
          @runtime.db.requires.each do |requirement|
            next unless relevant_filename?(requirement.location.filename)
            next unless requirement.resolved_filename
            next unless (loc = find_autoload_location(requirement.resolved_filename))
            add_error(requirement.location.filename, message: format(
              "In %s a require statement loads %s which appears in a Rails autoload path under %s. "\
              "Using `require` causes problems with autoloading, `require_dependency` should be used instead. "\
              "See http://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoloading-and-require for more details.\n",
              requirement.location.filename,
              requirement.resolved_filename,
              loc.path
            ))
          end
        end

        private

        def find_autoload_location(filename)
          @runtime.rails_autoload_locations.find do |loc|
            loc.files.include?(filename)
          end
        end
      end
    end
  end
end
