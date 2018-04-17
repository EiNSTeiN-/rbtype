# frozen_string_literal: true
require_relative '../base'
require 'active_support/inflector/methods'

module Rbtype
  module Lint
    module Rails
      class AutoloadConstants < Base
        def run
          @runtime.rails_autoload_locations.each do |loc|
            loc.files.each do |filename|
              next unless relevant_filename?(filename)
              const_name = expected_constant_name(loc.path, filename)
              return unless db = @runtime.db_for_file(filename)
              group = find_const_case_insensitive(db.definitions, const_name)

              if group == nil
                add_error(const_name, message: format(
                  "`%s` is expected to be defined by the file %s "\
                  "because this file is present in a Rails autoload path "\
                  "but the constant was not found in any file.\n",
                  const_name,
                  filename
                ))
              elsif group.size > 1
                add_error(const_name, message: format(
                  "`%s` is expected to be defined by the file %s "\
                  "because this file is present in a Rails autoload path "\
                  "but we found more than a single definition of this constant, "\
                  "which may cause autoload problems. This likely means that this constant "\
                  "conflicts with a constant defined in a gem. Defnitions were:\n",
                  const_name,
                  filename,
                  group.map(&:location).map(&:backtrace_line).join("\n")
                ))
              elsif !group.all? { |definition| definition.location.filename == filename }
                add_error(const_name, message: format(
                  "`%s` is expected to be defined by the file %s "\
                  "because this file is present in a Rails autoload path "\
                  "but we found definitions of this constant in other files. Defnitions were:\n%s\n",
                  const_name,
                  filename,
                  group.map(&:location).map(&:backtrace_line).join("\n")
                ))
              end
            end
          end
        end

        private

        def camelize(name)
          ActiveSupport::Inflector.camelize(name)
        end

        def expected_constant_name(basepath, filename)
          name = filename.sub(basepath, '').sub(/\.rb$/, '')
          klass_name = camelize(name)
          klass_name
        end

        def find_const_case_insensitive(definitions, const_name)
          wanted = const_name.downcase
          definitions.each do |key, value|
            return value if key.to_s.downcase == wanted
          end
          nil
        end
      end
    end
  end
end
