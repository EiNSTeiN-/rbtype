module Rbtype
  class ProcessedSource
    attr_reader :buffer, :ast

    class Builder < ::Parser::Builders::Default
      def n(type, children, source_map)
        Rbtype::AST::Node.new(type, children, location: source_map)
      end
    end

    def initialize(buffer, parser_klass)
      @buffer = buffer
      @parser = parser_klass.new(Builder.new)
      @parser.diagnostics.consumer = lambda do |diag|
        puts diag.render
      end
      @ast = parse
    end

    private

    def parse
      @parser.parse(@buffer)
    end
  end
end
