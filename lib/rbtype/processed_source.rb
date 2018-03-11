module Rbtype
  class ProcessedSource
    attr_reader :buffer, :ast, :lexical_context

    class Builder < ::Parser::Builders::Default
      def n(type, children, source_map)
        Rbtype::AST::Node.new(type, children, location: source_map)
      end
    end

    def initialize(buffer, parser_klass, relative_path: nil)
      @relative_path = relative_path
      @buffer = buffer
      @parser = parser_klass.new(Builder.new)
      @parser.diagnostics.consumer = lambda do |diag|
        #puts diag.render
      end
      @ast = parse
      @lexical_context = build_lexical_context
    end

    def filename
      @buffer.name
    end

    def friendly_filename
      filename.sub("#{@relative_path}/", '')
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

    private

    def parse
      @parser.parse(@buffer) unless raw_content.empty?
    end

    def build_lexical_context
      lexical_context = Lexical::UnnamedContext.new(nil)
      Lexical::Resolver.from_node(ast, lexical_parent: lexical_context) if ast
      lexical_context
    end
  end
end
