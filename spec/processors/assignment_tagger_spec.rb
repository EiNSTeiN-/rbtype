require 'spec_helper'
require 'rbtype'

describe Rbtype::Processors::AssignmentTagger do
  include ::AST::Sexp

  let(:filename) { 'test.rb' }
  let(:buffer) do
    buffer = Parser::Source::Buffer.new(filename)
    buffer.source = source
    buffer
  end
  let(:processed_source) { Rbtype::ProcessedSource.new(buffer, Parser::CurrentRuby) }
  let(:ast) { processed_source.ast }
  let(:handlers) do
    [
      Rbtype::Processors::NativeTypeTagger.new,
      described_class.new
    ]
  end
  let(:processor) { Rbtype::AST::Processor.new(handlers) }
  subject { processor.process(ast) }

  context "local variable" do
    let(:source) { 'foo = 1' }

    it { expect(subject.children[1].type).to eq :int }
    it { expect(subject.children[1].type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
    it { expect(subject.type).to eq :lvasgn }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
  end

  context "instance variable" do
    let(:source) { '@foo = 1' }

    it { expect(subject.children[1].type).to eq :int }
    it { expect(subject.children[1].type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
    it { expect(subject.type).to eq :ivasgn }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
  end

  context "class variable" do
    let(:source) { '@@foo = 1' }

    it { expect(subject.children[1].type).to eq :int }
    it { expect(subject.children[1].type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
    it { expect(subject.type).to eq :cvasgn }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
  end

  context "global variable" do
    let(:source) { '$foo = 1' }

    it { expect(subject.children[1].type).to eq :int }
    it { expect(subject.children[1].type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
    it { expect(subject.type).to eq :gvasgn }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
  end

  context "when no type identity is known" do
    let(:source) { 'foo = @bar' }

    it { expect(subject.children[1].type).to eq :ivar }
    it { expect(subject.children[1].type_identity).to eq nil }
    it { expect(subject.type).to eq :lvasgn }
    it { expect(subject.type_identity).to eq nil }
  end

  context "top level constant" do
    let(:source) { '::Foo = 1' }

    it { expect(subject.children[2].type).to eq :int }
    it { expect(subject.children[2].type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
    it { expect(subject.type).to eq :casgn }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
  end

  context "scoped constant" do
    let(:source) { 'Foo::Bar = 1' }

    it { expect(subject.children[2].type).to eq :int }
    it { expect(subject.children[2].type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
    it { expect(subject.type).to eq :casgn }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
  end

  context "unscoped constant" do
    let(:source) { 'Foo = 1' }

    it { expect(subject.children[2].type).to eq :int }
    it { expect(subject.children[2].type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
    it { expect(subject.type).to eq :casgn }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
  end
end
