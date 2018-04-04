require 'bundler'
require 'bundler/dsl'
require 'rubygems'

module Rbtype
  module Deps
    class Gems
      def initialize(gemfile, lockfile)
        @gemfile = Bundler::Dsl.evaluate(gemfile, lockfile, {})
      end

      def specs
        @specs ||= @gemfile.locked_gems.specs.map(&:__materialize__)
      end

      def requires
        @requires ||= @gemfile.requires
      end

      def spec(name)
        specs.find { |spec| spec.name == name }
      end
    end
  end
end
