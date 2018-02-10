require 'spec_helper'
require 'rbtype'

describe Rbtype::Processors::NativeTypeTagger do
  let(:filename) { 'test.rb' }
  let(:buffer) do
    buffer = Parser::Source::Buffer.new(filename)
    buffer.source = source
    buffer
  end
  let(:processed_source) { Rbtype::ProcessedSource.new(buffer, Parser::CurrentRuby) }
  let(:ast) { processed_source.ast }
  let(:handlers) { [described_class.new] }
  let(:processor) { Rbtype::AST::Processor.new(handlers) }
  subject { processor.process(ast) }

  context "tags dstr" do
    let(:source) { '"foo #{bar}"' }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end

  context "tags str" do
    let(:source) { "'foo'" }

    it { expect(subject.type).to eq :str }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end

  context "tags %Q()" do
    let(:source) { '%Q()' }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end

  context "tags %q()" do
    let(:source) { '%q()' }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end

  context "tags eval string ``" do
    let(:source) { "`exit`" }

    it { expect(subject.type).to eq :xstr }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end

  context "tags eval string %x{}" do
    let(:source) { "%x{exit}" }

    it { expect(subject.type).to eq :xstr }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end

  context "tags int" do
    let(:source) { "1" }

    it { expect(subject.type).to eq :int }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Integer') }
  end

  context "tags regexp //" do
    let(:source) { "/a/" }

    it { expect(subject.type).to eq :regexp }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Regexp') }
  end

  context "tags regexp %r{}" do
    let(:source) { "%r{a}" }

    it { expect(subject.type).to eq :regexp }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Regexp') }
  end

  context "tags array []" do
    let(:source) { "[]" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Array') }
  end

  context "tags array %w()" do
    let(:source) { "%w()" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Array') }
  end

  context "tags array %W()" do
    let(:source) { "%W()" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Array') }
  end

  context "tags array %i()" do
    let(:source) { "%i()" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Array') }
  end

  context "tags array %I()" do
    let(:source) { "%I()" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Array') }
  end

  context "tags symbol :sym" do
    let(:source) { ":sym" }

    it { expect(subject.type).to eq :sym }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Symbol') }
  end

  context "tags symbol %s()" do
    let(:source) { "%s()" }

    it { expect(subject.type).to eq :dsym }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Symbol') }
  end

  context "tags heredoc <<END" do
    let(:source) { "<<END\nEND" }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end

  context "tags heredoc <<~END" do
    let(:source) { "<<~END\nEND" }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end

  context "tags heredoc <<-END" do
    let(:source) { "<<-END\nEND" }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end

  context "tags float" do
    let(:source) { "1.0" }

    it { expect(subject.type).to eq :float }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Float') }
  end

  context "tags hash" do
    let(:source) { "{}" }

    it { expect(subject.type).to eq :hash }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Hash') }
  end

  context "tags true" do
    let(:source) { "true" }

    it { expect(subject.type).to eq :true }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('TrueClass') }
  end

  context "tags false" do
    let(:source) { "false" }

    it { expect(subject.type).to eq :false }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('FalseClass') }
  end

  context "tags nil" do
    let(:source) { "nil" }

    it { expect(subject.type).to eq :nil }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('NilClass') }
  end

  context "tags inclusive range" do
    let(:source) { "1..2" }

    it { expect(subject.type).to eq :irange }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Range') }
  end

  context "tags complex number" do
    let(:source) { "1i" }

    it { expect(subject.type).to eq :complex }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('Complex') }
  end

  context "tags __FILE__" do
    let(:source) { "__FILE__" }

    it { expect(subject.type).to eq :str }
    it { expect(subject.type_identity).to eq Rbtype::Type::NativeType.new('String') }
  end
end
