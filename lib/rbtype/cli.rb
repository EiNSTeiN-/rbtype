# frozen_string_literal: true

require 'rbtype'
require 'optparse'
require 'colorize'

require_relative 'cli/definitions'
require_relative 'cli/describe'
require_relative 'cli/nesting'
require_relative 'cli/lint'
require_relative 'cli/uses'

module Rbtype
  class CLI
    class ExitWithFailure < RuntimeError; end
    class ExitWithSuccess < RuntimeError; end

    ACTIONS = {
      definitions: Rbtype::CLI::Definitions,
      describe: Rbtype::CLI::Describe,
      lint: Rbtype::CLI::Lint,
      nesting: Rbtype::CLI::Nesting,
      uses: Rbtype::CLI::Uses,
    }

    def initialize
      @options = {}
      @actions = []
      @constants = []
      @files = []
      @lint_all_files = false
      @require_paths = []
      @rails_autoload_paths = []
    end

    def run(args = ARGV)
      load_options(args)

      if files.empty? && constants.empty?
        success!("specify either --file or --const...\n#{option_parser}")
      end

      ensure_files_exist

      if @actions.empty?
        success!("no actions to perform...\n#{option_parser}")
      end

      puts "Preparing cache..."
      prepare_cache
      @source_set = Rbtype::SourceSet.new(cache: @cache)

      puts "Loading #{gems.specs.size} gems..."
      locations = require_locations

      puts "Building runtime..."
      @runtime = Deps::RuntimeLoader.new(locations, [])
      @runtime.provided('thread')
      puts "Loading typedefs..."
      @runtime.load_sources(typedefs)
      puts "Requiring gems..."
      requires.each do |name|
        line = "require '#{name}'"
        puts "`#{line.green}`"
        @runtime.require_name(name)
      end
      puts "Done!"

      @runtime.rails_autoload_locations = rails_autoload_locations

      if files.size > 0
        puts "Loading #{files.size} files"
        @runtime.load_sources(app_sources)
        puts "Done!"
      end

      puts "Running linters..."
      @actions.each do |action|
        run_action(action)
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
    ensure
      @source_set.save_cache if @source_set
    end

    private

    def prepare_cache
      path = Pathname.new(Dir.pwd).join('tmp/type-cache')
      Dir.mkdir(path) unless File.exist?(path)
      @cache = Rbtype::Cache.new(path)
    end

    def build_file_loader(files)
      Deps::FileLoader.new(
        files,
        source_set: @source_set,
      )
    end

    def requires
      gems.ordered_requires.values.flatten
    end

    def typedefs
      basepath = File.expand_path(File.dirname(__FILE__))
      files = [File.join(basepath, 'ruby-typedef.rb')]
      loader = build_file_loader(files)
      loader.sources
    end

    def app_sources
      @app_sources ||= begin
        loader = build_file_loader(files)
        loader.sources
      end
    end

    def rails_autoload_locations
      @rails_autoload_sources ||= begin
        @rails_autoload_paths.map do |path|
          files = Dir["#{path}/**/*.rb"]
          loader = build_file_loader(files)
          Deps::RailsAutoloadLocation.new(path, loader.sources)
        end
      end
    end

    def environment_require_locations
      paths = %x(ruby -e 'puts $:').split("\n")
      missing = paths
        .reject { |path| spec_load_paths.include?(path) }
        .select { |path| Dir.exist?(path) }
      missing.map do |path|
        files = Dir["#{path}/**/*.rb"]
        loader = build_file_loader(files)
        Deps::RequireLocation.new(path, loader.sources)
      end
    end

    def explicit_require_locations
      @require_paths.map do |path|
        expanded = File.expand_path(path)
        files = Dir["#{expanded}/**/*.rb"]
        loader = build_file_loader(files)
        Deps::RequireLocation.new(path, loader.sources)
      end
    end

    def spec_loaders
      @spec_loaders ||= gems.specs.map do |spec|
        Deps::SpecLoader.new(spec, ignore_errors: true, source_set: @source_set)
      end
    end

    def spec_load_paths
      @spec_load_paths ||= spec_loaders.map do |spec_loader|
        spec_loader.full_require_paths || []
      end.flatten
    end

    def spec_require_locations
      @spec_require_locations ||= begin
        spec_loaders.map do |spec_loader|
          begin
            locations = spec_loader.full_require_paths.map do |path|
              sources = spec_loader.sources.select { |source| source.filename.start_with?(path) }
              Deps::RequireLocation.new(path, sources)
            end
          rescue => e
            warn "Error while dependency #{spec_loader.short_name}: #{e}".red
            raise
          end
        end.flatten
      end
    end

    def require_locations
      @require_locations ||= [
        *environment_require_locations,
        *spec_require_locations,
        *explicit_require_locations,
      ].reject { |loc| loc.sources.size == 0 }
    end

    def gemfile
      Bundler::SharedHelpers.default_gemfile
    end

    def lockfile
      Bundler::SharedHelpers.default_lockfile
    end

    def gems
      @gems ||= Deps::Gems.new(gemfile, lockfile)
    end

    def action_options
      { constants: constants, files: files, lint_all_files: @lint_all_files }
    end

    def run_action(name)
      klass = ACTIONS[name]
      if klass
        puts
        puts "---- #{name} ----"
        puts klass.new(@runtime, **action_options)
      else
        failure!("No such action: #{name}")
      end
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

    def constants
      @constants.map do |name|
        ref = Constants::ConstReference.from_string(name)
        if ref.explicit_base?
          ref
        else
          Constants::ConstReference.base.join(ref)
        end
      end
    end

    def failure!(msg)
      raise ExitWithFailure, msg
    end

    def success!(msg)
      raise ExitWithSuccess, msg
    end

    def ensure_files_exist
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

        opts.on("--const [const]", "Constants to run actions against") do |config|
          @constants << config
        end

        ACTIONS.keys.each do |action|
          opts.on("--#{action}", "Run '#{action}' on given files or constants") do |config|
            @actions << action
          end
        end

        opts.on("--lint-all-files", "When running --lint, consider gem sources as part of the scope") do |config|
          @lint_all_files = config
        end

        opts.on("--require-path [pathname]", "Files to parse") do |config|
          @require_paths << config
        end

        opts.on("--rails-autoload-paths [pathname]", "Directories that are registered "\
            "with Rails autoload functionality and obey autloading rules") do |config|
          @rails_autoload_paths.concat(config.split(' '))
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
