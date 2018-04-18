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

    GEM_CACHE_NAME = 'global-gem-cache'

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
      @diag = Rbtype::DiagnosticEngine.new
      @diag.consumer = lambda do |diag|
        puts "#{diag.reason.to_s.red}: #{diag.message}"
      end
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

      prepare_cache
      @source_set = Rbtype::SourceSet.new(diagnostic_engine: @diag)

      puts "Loading #{gems.specs.size} gems in the runtime..."
      @runtime = Deps::RuntimeLoader.new(@source_set, require_locations, [], diagnostic_engine: @diag)
      @runtime.provided('thread')
      puts "Loading typedefs..."
      @runtime.load_files(typedefs)
      puts "Requiring gems..."
      ordered_requires.each do |name|
        line = "require '#{name}'"
        puts "`#{line.green}`"
        begin
          source = @runtime.find_source(name)
          if source
            @runtime.load_source(source)
          else
            puts "cannot load such file -- #{name}"
          end
        rescue Deps::RuntimeLoader::UnsupposedFileFormat => e
          puts "#{e.class}: #{e.message.red}"
        end
      end
      puts "Done!"

      @runtime.rails_autoload_locations = rails_autoload_locations

      if files.size > 0
        puts "Loading #{files.size} files"
        @runtime.load_files(files)
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
      Rbtype::Cache.save
      if Rbtype::Cache.stats
        stats = Rbtype::Cache.stats.map { |k,v| "#{k}=#{v} ms" }
        puts "cache stats: #{stats.join(', ')}"
      end
    end

    private

    def prepare_cache
      path = Pathname.new(Dir.pwd).join('tmp/type-cache')
      Dir.mkdir(path) unless File.exist?(path)
      Rbtype::Cache.setup(path)
    end

    def ordered_requires
      @ordered_requires ||= gems.ordered_requires.values.flatten
    end

    def typedefs
      basepath = File.expand_path(File.dirname(__FILE__))
      [File.join(basepath, 'ruby-typedef.rb')]
    end

    def rails_autoload_locations
      @rails_autoload_locations ||= begin
        @rails_autoload_paths.map do |path|
          files = Dir["#{path}/**/*"].select { |filename| File.file?(filename) }
          Deps::RailsAutoloadLocation.new(path, files)
        end
      end
    end

    def environment_require_locations
      paths = %x(ruby -e 'puts $:').split("\n")
      missing = paths
        .reject { |path| spec_require_paths.include?(path) }
        .select { |path| Dir.exist?(path) }
      missing.map do |path|
        files = Dir["#{path}/**/*"].select { |filename| File.file?(filename) }
        Deps::RequireLocation.new(path, files)
      end
    end

    def explicit_require_locations
      @require_paths.map do |path|
        expanded = File.expand_path(path)
        files = Dir["#{expanded}/**/*"].select { |filename| File.file?(filename) }
        Deps::RequireLocation.new(path, files)
      end
    end

    def spec_require_locations
      @spec_require_locations ||= gems.specs.map(&:require_locations).flatten
    end

    def spec_require_paths
      @spec_load_paths ||= spec_require_locations.map(&:path)
    end

    def require_locations
      @require_locations ||= [
        *environment_require_locations,
        *spec_require_locations,
        *explicit_require_locations,
      ].reject { |loc| loc.files.size == 0 }
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
        .map { |f| Dir[f] }.flatten
        .map { |f| File.expand_path(f, Dir.pwd) }
        .select { |f| f.end_with?('.rb') && File.file?(f) }
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
