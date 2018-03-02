# frozen_string_literal: true

require 'rbtype'
require 'optparse'
require 'colorize'

require_relative 'cli/describe'
require_relative 'cli/nesting'

module Rbtype
  class CLI
    class ExitWithFailure < RuntimeError; end
    class ExitWithSuccess < RuntimeError; end

    def initialize
      @options = {}
      @actions = []
      @targets = []
      @files = []
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

      resolve_world(files)

      @actions.each do |action|
        @targets.each do |target|
          puts
          puts "---- #{action} @ #{target} ----"
          send("run_action_#{action}", target)
        end
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

    def relative_filename(filename)
      filename.sub("#{File.expand_path('.', Dir.pwd)}/", '')
    end

    def resolve_world(files)
      @resolver = Rbtype::Namespace::Resolver.new
      nesting_root = Rbtype::Namespace::ConstReference.new([nil])
      files.each do |filename|
        ast = parse_file(filename)
        file_context = Rbtype::Namespace::Context.new
        @resolver.process(ast, file_context, [nesting_root])
      end
    end

    def parse_file(filename)
      buffer = ::Parser::Source::Buffer.new(relative_filename(filename))
      buffer.source = File.read(filename)
      buffer
      Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24).ast
    end

    def run_action_describe(target)
      ref = build_const_name(target)
      puts Describe.new(@resolver, ref)
    end

    def run_action_nesting(target)
      ref = build_const_name(target)
      puts Nesting.new(@resolver, ref)
    end

    def build_const_name(target)
      parts = target.split('::', -1).map { |part| part&.to_sym }
      Namespace::ConstReference.new(parts)
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

        opts.on("--nesting", "Describe the target") do |config|
          @actions << :nesting
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
