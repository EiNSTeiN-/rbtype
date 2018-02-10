require 'parser/current'

module Rbtype
  class Engine
    attr_reader :sources

    def initialize(parser_klass: Parser::CurrentRuby)
      @parser_klass = parser_klass
      @sources = []
    end

    def process_source(buffer)
      @sources << ProcessedSource.new(buffer, @parser_klass)
    end

    def run
      processor = Rbtype::AST::Processor.new([
        Rbtype::Processors::NativeTypeTagger.new,
      ])
      @sources.each do |source|
        processor.process_all(source.ast)
      end
    end
  end
end
