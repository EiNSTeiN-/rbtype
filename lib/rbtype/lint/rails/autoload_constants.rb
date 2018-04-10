require_relative '../base'
require 'active_support/inflector/methods'

module Rbtype
  module Lint
    module Rails
      class AutoloadConstants < Base
        def run
          @runtime.rails_autoload_locations.each do |loc|
            loc.sources.each do |source|
              next unless relevant_filename?(source.filename)
              const_ref = expected_constant(loc.path, source.filename)
              #puts "expect #{source.filename} to define #{const_ref}"
              required_file = @runtime.required[source.filename]
              group = find_const_case_insensitive(required_file, const_ref)
              next if group

              found = if group
                format(
                  "If the application works despite this issue, the constant may be provided by "\
                  "another file loaded in the namespace prior to this one. The constant `%s` was "\
                  "found in your application in the following files:\n%s",
                  group.map(&:backtrace_line).join("\n")
                )
              else
                "The constant could not be found in any file."
              end

              add_error(const_ref, message: format(
                "`%s` is expected to be defined by the file %s "\
                "because this file is present in a Rails autoload path "\
                "but the constant was not found in this file. #{found}\n",
                const_ref,
                source.filename
              ))
            end
          end
        end

        private

        def camelize(name)
          ActiveSupport::Inflector.camelize(name)
        end

        def expected_constant(basepath, filename)
          name = filename.sub(basepath, '').sub(/\.rb$/, '')
          klass_name = camelize(name)
          Constants::ConstReference.base.join(
            Constants::ConstReference.from_string(klass_name)
          )
        end

        def find_const_case_insensitive(required_file, const_ref)
          wanted = const_ref.to_s.downcase
          required_file.definitions.each do |key, value|
            return value if key.to_s.downcase == wanted
          end
          nil
        end
      end
    end
  end
end
