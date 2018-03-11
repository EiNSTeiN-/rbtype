require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::MissingDefinition do
  let(:filename) { 'test.rb' }
  let(:buffer) do
    buffer = ::Parser::Source::Buffer.new(filename)
    buffer.source = source
    buffer
  end
  let(:processed_source) { Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24) }
  let(:ast) { processed_source.ast }
  let(:context) { Rbtype::Lexical::UnnamedContext.new }
  let(:resolver) { Rbtype::Lexical::Resolver.from_node(ast, context: context) }
  let(:linter) { described_class.new(resolver) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'both a class and a module' do
      let(:source) { <<~EOF }
        class A::B; end
        class A::C; end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        Missing definition for ::A
        - in definition of ::A::B at test.rb:1
        - in definition of ::A::C at test.rb:2
      ERR
    end
  end
end
