# frozen_string_literal: true
require 'bundler'
require 'bundler/dsl'
require 'rubygems'
require 'active_support/inflector/methods'

module Rbtype
  module Deps
    class RailsAutoloadLocation < RequireLocation
      def find_autoloaded_file(const_ref)
        filename = const_name_to_path(const_ref)
        find(filename)
      end

      def matching_folder?(const_ref)
        path = const_name_to_path(const_ref)
        directory_exist?(path)
      end

      private

      def const_name_to_path(const_ref)
        ActiveSupport::Inflector.underscore(const_ref.without_explicit_base.to_s)
      end
    end
  end
end
