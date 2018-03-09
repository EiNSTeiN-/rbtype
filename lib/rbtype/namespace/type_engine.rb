module Rbtype
  class TypeEngine
    attr_reader :ast

    def initialize(ast)
      @ast = ast
    end

    def run
      processor = Rbtype::AST::Processor.new([
        Rbtype::Processors::TypeIdentity.new,
        Rbtype::Processors::ConstReferenceTagger.new,
        Rbtype::Processors::InstantiationTagger.new,
      ])
      processor.process_all(ast)
    end

    def self.run(node)
      new([node]).run&.first
    end
  end
end
