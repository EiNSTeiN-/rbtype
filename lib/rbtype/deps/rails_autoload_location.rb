# frozen_string_literal: true

module Rbtype
  module Deps
    class RailsAutoloadLocation < RequireLocation
      def directory_exist?(name)
        full_path = expand(name)
        return false unless full_path.start_with?("#{path}/")
        full_path = "#{full_path}/" unless full_path.end_with?('/')
        @files.any? do |filename|
          filename.start_with?(full_path)
        end
      end
    end
  end
end
