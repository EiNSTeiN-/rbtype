# frozen_string_literal: true
require_relative 'cacheable'

module Rbtype
  class ProcessedSource
    include Cacheable

    attr_reader :filename, :raw_content
    attr_accessor :diagnostic_engine

    class Builder < ::Parser::Builders::Default
      def n(type, children, source_map)
        Rbtype::AST::Node.new(type, children, location: source_map)
      end
    end

    def initialize(filename, raw_content, parser_klass, relative_path: nil, diagnostic_engine: nil)
      @relative_path = relative_path
      @filename = filename
      @raw_content = raw_content
      @parser_klass = parser_klass
      @diagnostic_engine = diagnostic_engine
      @ast = nil
      cache_register!
    end

    def self.initialize_from_cache(filename)
      Cache.load_object_by_key(cache_key(filename: filename))
    end

    def ast
      @ast ||= parse
    end

    def ==(other)
      other.is_a?(Rbtype::ProcessedSource) &&
        other.filename == filename &&
        other.raw_content == raw_content
    end

    def hash
      [raw_content, filename].hash
    end

    def friendly_filename
      if @relative_path
        filename.sub("#{@relative_path}/", '')
      else
        filename
      end
    end

    def to_s
      "#<#{self.class} #{friendly_filename}>"
    end

    def inspect
      "#<#{self.class} file=#{friendly_filename}>"
    end

    def marshal_dump
      {
        relative_path: @relative_path,
        filename: @filename,
        raw_content: @raw_content,
        parser_klass: @parser_klass,
        ast: @ast,
      }
    end

    def marshal_load(args)
      @relative_path = args[:relative_path]
      @filename = args[:filename]
      @raw_content = args[:raw_content]
      @parser_klass = args[:parser_klass]
      @ast = args[:ast]
      cache_register!
    end

    def cacheable?
      File.exist?(filename) && @ast != nil
    end

    def cache_metadata
      metadata = { filename: filename }
      metadata[:mtime] = File.mtime(filename) if File.exist?(filename)
      metadata
    end

    def self.cache_key(filename:, **)
      "#{self}:#{filename}"
    end

    def self.cache_stale?(filename:, mtime:, **)
      return true unless File.exist?(filename)
      current_mtime = File.mtime(filename)
      current_mtime > mtime
    end

    def buffer
      @buffer ||= begin
        buffer = ::Parser::Source::Buffer.new(filename)
        buffer.source = raw_content
        buffer
      end
    end

    private

    def parser
      @parser ||= begin
        parser = @parser_klass.new(Builder.new)
        parser.diagnostics.consumer = lambda do |diag|
          next unless @diagnostic_engine

          diag = Diagnostic.new(diag.level, diag.reason, diag.message,
            diag.arguments, Constants::Location.new(diag.location))
          @diagnostic_engine.process(diag)
        end
        parser
      end
    end

    def parse
      parser.parse(buffer) unless raw_content.empty?
    end
  end
end
