require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::UnresolvedReference do
  let(:filename) { 'test.rb' }
  let(:buffer) do
    buffer = ::Parser::Source::Buffer.new(filename)
    buffer.source = source
    buffer
  end
  let(:processed_source) { Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24) }
  let(:ast) { processed_source.ast }
  let(:context) { Rbtype::Lexical::UnnamedContext.new(nil) }
  let(:resolver) { Rbtype::Lexical::Resolver.from_node(ast, lexical_parent: context) }
  let(:linter) { described_class.new(resolver) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'with unknown reference' do
      let(:source) { <<~EOF }
        class A < B; end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq 'Class ancestor `B` is not defined for class `::A` at test.rb:1' }
    end

    context 'with known reference with a definition' do
      let(:source) { <<~EOF }
        class B; end
        class A < B; end
      EOF
      it { expect(subject).to eq [] }
    end

    context 'with known reference without a definition' do
      let(:source) { <<~EOF }
        class B::C; end
        class A < B; end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq 'Class ancestor `B` is not defined for class `::A` at test.rb:2' }
    end
  end
end
