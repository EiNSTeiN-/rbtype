require 'spec_helper'
require 'rbtype'

describe Rbtype::Lexical::NamedContext do
  let(:source) { 'class Foo; end' }
  let(:name_ref) { const_ref(:Foo) }
  let(:lexical_context) { Rbtype::Lexical::UnnamedContext.new(:top_level, nil) }
  let(:processed_source) { build_processed_source(source) }
  let(:ast) { processed_source.ast }
  let(:superclass_expr) { nil }
  let(:named_context) { described_class.new(:named_context, ast, name_ref, superclass_expr, lexical_context) }
  subject { named_context }

  describe 'location' do
    let(:name_ref) { const_ref(:Foo) }
    it { expect(subject.location).to eq ast.location.expression }
  end

  describe 'namespaced?' do
    context 'when only one level' do
      let(:name_ref) { const_ref(:Foo) }
      it { expect(subject.namespaced?).to eq false }
    end

    context 'when more than one level' do
      let(:name_ref) { const_ref(:Foo, :Bar) }
      it { expect(subject.namespaced?).to eq true }
    end

    context 'when defined on top level' do
      let(:name_ref) { const_ref(nil, :Foo) }
      it { expect(subject.namespaced?).to eq true }
    end
  end

  describe 'nesting' do
    it { expect(subject.nesting).to eq [subject, lexical_context] }
  end
end
