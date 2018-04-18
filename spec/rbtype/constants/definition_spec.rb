require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::Definition do
  let(:parent_nesting) { nil }
  let(:full_path) { const_ref(nil, :MyClass) }
  let(:path) { const_ref(:MyClass) }
  let(:type) { :class }
  let(:body_node) { nil }
  let(:location) { double('Location', filename: "test.rb", line: 1, source_line: "class MyClass") }
  let(:definition) { described_class.new(parent_nesting, full_path, path, type, body_node, location) }

  describe 'to_s' do
    subject { definition.to_s }
    it { expect(subject).to eq '#<Rbtype::Constants::Definition class MyClass>' }
  end

  describe 'inspect' do
    subject { definition.inspect }
    it { expect(subject).to eq '#<Rbtype::Constants::Definition type=class '\
      'full_path=::MyClass path=MyClass nesting=[::MyClass]>' }
  end

  describe 'parent_nesting' do
    let(:parent_nesting) { [double('Definition')] }
    subject { definition.parent_nesting }
    it { expect(subject).to eq parent_nesting }
  end

  describe 'nesting' do
    subject { definition.nesting }
    it { expect(subject).to eq [definition] }

    context 'when parent is not nil' do
      let(:parent_nesting) { [double('Definition')] }
      it { expect(subject).to eq [definition, *parent_nesting] }
    end
  end

  describe 'name' do
    subject { definition.name }

    context 'when namespaced' do
      let(:path) { const_ref(:MyNamespace, :MyClass) }
      it { expect(subject).to eq const_ref(:MyClass) }
    end
  end

  describe 'namespaced?' do
    subject { definition.namespaced? }

    context 'when not namespaced' do
      it { expect(subject).to eq false }
    end

    context 'when namespaced' do
      let(:path) { const_ref(:MyNamespace, :MyClass) }
      it { expect(subject).to eq true }
    end
  end
end
