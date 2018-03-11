# frozen_string_literal: true

require 'rbtype'
require 'optparse'
require 'colorize'

require_relative 'cli/describe'
require_relative 'cli/nesting'
require_relative 'cli/lint'
require_relative 'cli/ancestors'

module Rbtype
  class CLI
    class ExitWithFailure < RuntimeError; end
    class ExitWithSuccess < RuntimeError; end

    def initialize
      @options = {}
      @actions = []
      @targets = []
      @files = []
      @load_gems = false
    end

    def run(args = ARGV)
      load_options(args)

      @targets.push(*args)

      if files.empty?
        success!("no files given...\n#{option_parser}")
      end

      ensure_files_exist(files)

      if @actions.empty?
        success!("no actions to perform...\n#{option_parser}")
      end

      sources = [
        *app_sources(files),
        *(dependencies_sources if @load_gems),
      ]

      @actions.each do |action|
        send("run_action_#{action}", @targets)
      end

      true
    rescue OptionParser::InvalidOption, OptionParser::InvalidArgument, ExitWithFailure => e
      warn e.message.red
      false
    rescue ExitWithSuccess => e
      puts e.message
      true
    rescue => e
      warn "#{e.class}: #{e.message}\n#{e.backtrace.join("\n")}".red
      false
    end

    private

    def app_sources(files)
      loader = Deps::FileLoader.new(files, relative_path: Dir.pwd, relative_name: '(pwd)')
      begin
        loader.sources
      rescue => e
        warn "Error while loading app: #{e}".red
        raise
      end
    end

    def dependencies_sources
      gems = Deps::Gems.new(gemfile, lockfile)
      gems.specs.map do |spec|
        spec_loader = Deps::SpecLoader.new(spec)
        begin
          spec_loader.sources
        rescue => e
          warn "Error while dependency #{spec_loader.short_name}: #{e}".red
          raise
        end
      end
    end

    def gemfile
      Bundler::SharedHelpers.default_gemfile
    end

    def lockfile
      Bundler::SharedHelpers.default_lockfile
    end

    def run_action_describe(targets)
      targets.each do |target|
        puts
        puts "---- describe @ #{target} ----"
        ref = build_const_name(target)
        puts Describe.new(@resolver, ref)
      end
    end

    def run_action_nesting(targets)
      targets.each do |target|
        puts
        puts "---- nesting @ #{target} ----"
        ref = build_const_name(target)
        puts Nesting.new(@resolver, ref)
      end
    end

    def run_action_ancestors(targets)
      targets.each do |target|
        puts
        puts "---- ancestors @ #{target} ----"
        ref = build_const_name(target)
        puts Ancestors.new(@resolver, ref)
      end
    end

    def run_action_lint(_)
      puts Lint.new(@resolver)
    end

    def build_const_name(target)
      parts = target.split('::', -1).map { |part| part&.to_sym }
      Lexical::ConstReference.new(parts)
    end

    def load_options(args)
      option_parser.parse!(args)
    end

    def files
      @files
        .map { |f| f.include?('*') ? Dir[f] : f }
        .flatten
        .map { |f| File.expand_path(f, Dir.pwd) }
    end

    def failure!(msg)
      raise ExitWithFailure, msg
    end

    def success!(msg)
      raise ExitWithSuccess, msg
    end

    def ensure_files_exist(files)
      files.each do |filename|
        unless File.exist?(filename)
          failure!("#{filename}: does not exist")
        end
      end
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: rbtype [options] [target, ...]"

        opts.on("--file [file]", "Files to parse") do |config|
          @files << config
        end

        opts.on("--target [const]", "Constants to run actions against") do |config|
          @targets << config
        end

        opts.on("--describe", "Describe the target") do |config|
          @actions << :describe
        end

        opts.on("--lint", "Lint") do |config|
          @actions << :lint
        end

        opts.on("--nesting", "Describe the target") do |config|
          @actions << :nesting
        end

        opts.on("--ancestors", "Display the target's ancestors tree") do |config|
          @actions << :ancestors
        end

        opts.on("--load-gems", "Load gems before analysis") do |config|
          @load_gems = true
        end

        opts.on_tail("-h", "--help", "Show this message") do
          success!(opts)
        end

        opts.on_tail("--version", "Show version") do
          success!(ERBLint::VERSION)
        end
      end
    end
  end
end
