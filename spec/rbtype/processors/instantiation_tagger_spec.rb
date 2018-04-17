require 'spec_helper'
require 'rbtype'

describe Rbtype::Processors::InstantiationTagger do
  let(:filename) { 'test.rb' }
  let(:processed_source) { Rbtype::ProcessedSource.new(filename, source, Parser::Ruby24) }
  let(:ast) { processed_source.ast }
  let(:handlers) { [Rbtype::Processors::ConstReferenceTagger.new, described_class.new] }
  let(:processor) { Rbtype::AST::Processor.new(handlers) }
  subject { processor.process(ast) }

  context "simple constant" do
    let(:source) { 'Hash.new' }

    it { expect(subject.type).to eq :send }
    it { expect(subject.type_identity).to eq instance_of(const_ref(:Hash)) }
  end

  context "scoped constant" do
    let(:source) { 'Foo::Bar.new' }

    it { expect(subject.type).to eq :send }
    it { expect(subject.type_identity).to eq instance_of(const_ref(:Foo, :Bar)) }
  end

  context "top level constant" do
    let(:source) { '::Bar.new' }

    it { expect(subject.type).to eq :send }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Bar)) }
  end

  context "all caps constant" do
    let(:source) { 'FOO.new' }

    it { expect(subject.type).to eq :send }
    it { expect(subject.type_identity).to eq instance_of(const_ref(:FOO)) }
  end
end
