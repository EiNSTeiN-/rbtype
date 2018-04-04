module Rbtype
  class ProcessedSource
    attr_reader :buffer, :lexical_context

    class Builder < ::Parser::Builders::Default
      def n(type, children, source_map)
        Rbtype::AST::Node.new(type, children, location: source_map)
      end
    end

    def initialize(buffer, parser_klass, relative_path: nil)
      @relative_path = relative_path
      @buffer = buffer
      @parser_klass = parser_klass
      @ast = nil
    end

    def ast
      @ast ||= parse
    end

    def filename
      @buffer.name
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

    def raw_content
      @buffer.source
    end

    def to_s
      "#{self.class}(#{friendly_filename})"
    end

    def inspect
      "#<#{self.class} file=#{friendly_filename}>"
    end

    def marshal_dump
      {
        relative_path: @relative_path,
        buffer: @buffer,
        parser_klass: @parser_klass,
        ast: @ast,
        lexical_context: @lexical_context,
      }
    end

    def marshal_load(args)
      @relative_path = args[:relative_path]
      @buffer = args[:buffer]
      @parser_klass = args[:parser_klass]
      @ast = args[:ast]
      @lexical_context = args[:lexical_context]
    end

    private

    def parser
      @parser ||= begin
        parser = @parser_klass.new(Builder.new)
        parser.diagnostics.consumer = lambda do |diag|
          #puts diag.render
        end
        parser
      end
    end

    def parse
      parser.parse(@buffer) unless raw_content.empty?
    end
  end
end
