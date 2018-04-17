# frozen_string_literal: true
require 'bundler'
require 'bundler/dsl'
require 'rubygems'
require_relative 'spec'

module Rbtype
  module Deps
    class Gems
      def initialize(gemfile, lockfile)
        @gemfile = Bundler::Dsl.evaluate(gemfile, lockfile, {})
      end

      def default_specs
        @gemfile.specs_for([:default, :runtime]).materialized_for_all_platforms
      end

      def specs
        @specs ||= default_specs.map{ |spec| Spec.new(spec) }
      end

      def requires
        @requires ||= @gemfile.requires.select { |name| spec(name) }
      end

      def ordered_requires
        @ordered_requires ||= begin
          set = Set.new
          requires.each do |name, files|
            add_required_spec_dependencies(set, name)
          end
          Hash[set.map { |name| [name, requires[name]] }]
        end
      end

      def spec(name)
        specs.find { |spec| spec.name == name }
      end

      private

      def add_required_spec_dependencies(set, name)
        spec = spec(name)
        required_dependencies = spec.dependencies.map(&:name).select { |name| requires.include?(name) }
        required_dependencies.each do |dep|
          add_required_spec_dependencies(set, dep)
        end
        set << name
      end
    end
  end
end
