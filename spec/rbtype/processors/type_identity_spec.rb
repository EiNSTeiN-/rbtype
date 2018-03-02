require 'spec_helper'
require 'rbtype'

describe Rbtype::Processors::TypeIdentity do
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

  context "dstr" do
    let(:source) { '"foo #{bar}"' }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "str" do
    let(:source) { "'foo'" }

    it { expect(subject.type).to eq :str }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "%Q()" do
    let(:source) { '%Q()' }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "%q()" do
    let(:source) { '%q()' }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "eval string ``" do
    let(:source) { "`exit`" }

    it { expect(subject.type).to eq :xstr }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "eval string %x{}" do
    let(:source) { "%x{exit}" }

    it { expect(subject.type).to eq :xstr }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "int" do
    let(:source) { "1" }

    it { expect(subject.type).to eq :int }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Integer)) }
  end

  context "regexp //" do
    let(:source) { "/a/" }

    it { expect(subject.type).to eq :regexp }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Regexp)) }
  end

  context "regexp %r{}" do
    let(:source) { "%r{a}" }

    it { expect(subject.type).to eq :regexp }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Regexp)) }
  end

  context "array []" do
    let(:source) { "[]" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Array)) }
  end

  context "array %w()" do
    let(:source) { "%w()" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Array)) }
  end

  context "array %W()" do
    let(:source) { "%W()" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Array)) }
  end

  context "array %i()" do
    let(:source) { "%i()" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Array)) }
  end

  context "array %I()" do
    let(:source) { "%I()" }

    it { expect(subject.type).to eq :array }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Array)) }
  end

  context "symbol :sym" do
    let(:source) { ":sym" }

    it { expect(subject.type).to eq :sym }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Symbol)) }
  end

  context "symbol %s()" do
    let(:source) { "%s()" }

    it { expect(subject.type).to eq :dsym }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Symbol)) }
  end

  context "heredoc <<END" do
    let(:source) { "<<END\nEND" }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "heredoc <<~END" do
    let(:source) { "<<~END\nEND" }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "heredoc <<-END" do
    let(:source) { "<<-END\nEND" }

    it { expect(subject.type).to eq :dstr }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "float" do
    let(:source) { "1.0" }

    it { expect(subject.type).to eq :float }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Float)) }
  end

  context "hash" do
    let(:source) { "{}" }

    it { expect(subject.type).to eq :hash }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Hash)) }
  end

  context "true" do
    let(:source) { "true" }

    it { expect(subject.type).to eq :true }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :TrueClass)) }
  end

  context "false" do
    let(:source) { "false" }

    it { expect(subject.type).to eq :false }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :FalseClass)) }
  end

  context "nil" do
    let(:source) { "nil" }

    it { expect(subject.type).to eq :nil }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :NilClass)) }
  end

  context "inclusive range" do
    let(:source) { "1..2" }

    it { expect(subject.type).to eq :irange }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Range)) }
  end

  context "complex number" do
    let(:source) { "1i" }

    it { expect(subject.type).to eq :complex }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Complex)) }
  end

  context "rational number" do
    let(:source) { "2.0r" }

    it { expect(subject.type).to eq :rational }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Rational)) }
  end

  context "__FILE__" do
    let(:source) { "__FILE__" }

    it { expect(subject.type).to eq :str }
    it { expect(subject.type_identity).to eq instance_of(string_class_ref) }
  end

  context "local variable" do
    let(:source) { 'foo = 1' }

    it { expect(subject.children[1].type).to eq :int }
    it { expect(subject.children[1].type_identity).to eq instance_of(const_ref(nil, :Integer)) }
    it { expect(subject.type).to eq :lvasgn }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Integer)) }
  end

  context "instance variable" do
    let(:source) { '@foo = 1' }

    it { expect(subject.children[1].type).to eq :int }
    it { expect(subject.children[1].type_identity).to eq instance_of(const_ref(nil, :Integer)) }
    it { expect(subject.type).to eq :ivasgn }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Integer)) }
  end

  context "class variable" do
    let(:source) { '@@foo = 1' }

    it { expect(subject.children[1].type).to eq :int }
    it { expect(subject.children[1].type_identity).to eq instance_of(const_ref(nil, :Integer)) }
    it { expect(subject.type).to eq :cvasgn }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Integer)) }
  end

  context "global variable" do
    let(:source) { '$foo = 1' }

    it { expect(subject.children[1].type).to eq :int }
    it { expect(subject.children[1].type_identity).to eq instance_of(const_ref(nil, :Integer)) }
    it { expect(subject.type).to eq :gvasgn }
    it { expect(subject.type_identity).to eq instance_of(const_ref(nil, :Integer)) }
  end

  context "when no type identity is known" do
    let(:source) { 'foo = @bar' }

    it { expect(subject.children[1].type).to eq :ivar }
    it { expect(subject.children[1].type_identity).to eq nil }
    it { expect(subject.type).to eq :lvasgn }
    it { expect(subject.type_identity).to eq nil }
  end

  context "defined?" do
    let(:source) { 'defined?(a)' }

    it { expect(subject.type).to eq :defined? }
    it { expect(subject.type_identity).to eq boolean_instance_ref }
  end
end
