require 'parser/ruby24'

module Rbtype
  class Engine
    attr_reader :sources

    def initialize(parser_klass: Parser::Ruby24)
      @parser_klass = parser_klass
      @sources = []
    end

    def process_source(buffer)
      @sources << ProcessedSource.new(buffer, @parser_klass)
    end

    def run
      processor = Rbtype::AST::Processor.new([
        Rbtype::Processors::NativeTypeTagger.new,
        Rbtype::Processors::ConstReferenceTagger.new,
        Rbtype::Processors::InstanciationTagger.new,
      ])
      @sources.each do |source|
        processor.process_all(source.ast)
      end
    end
  end
end
