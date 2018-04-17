require 'spec_helper'
require 'rbtype'

describe Rbtype::Processors::ConstReferenceTagger do
  let(:filename) { 'test.rb' }
  let(:processed_source) { Rbtype::ProcessedSource.new(filename, source, Parser::Ruby24) }
  let(:ast) { processed_source.ast }
  let(:handlers) { [described_class.new] }
  let(:processor) { Rbtype::AST::Processor.new(handlers) }
  subject { processor.process(ast) }

  context "simple constant" do
    let(:source) { 'Hash' }

    it { expect(subject.type).to eq :const }
    it { expect(subject.type_identity).to eq const_ref(:Hash) }
  end

  context "scoped constant" do
    let(:source) { 'Foo::Bar' }

    it { expect(subject.type).to eq :const }
    it { expect(subject.type_identity).to eq const_ref(:Foo, :Bar) }
  end

  context "top level constant" do
    let(:source) { '::Bar' }

    it { expect(subject.type).to eq :const }
    it { expect(subject.type_identity).to eq const_ref(nil, :Bar) }
  end

  context "all caps constant" do
    let(:source) { 'FOO' }

    it { expect(subject.type).to eq :const }
    it { expect(subject.type_identity).to eq const_ref(:FOO) }
  end
end
