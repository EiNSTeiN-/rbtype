require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::Group do
  let(:full_path) { const_ref(nil, :MyClass) }
  let(:definitions) { nil }
  let(:group) { described_class.new(full_path, definitions) }

  describe 'name' do
    subject { group.name }
    it { expect(subject).to eq const_ref(:MyClass) }

    context 'with long path' do
      let(:full_path) { const_ref(nil, :Foo, :Bar, :Baz) }
      it { expect(subject).to eq const_ref(:Baz) }
    end
  end

  describe 'to_s' do
    let(:definitions) { [double('Definition', full_path: const_ref(:A))] }
    subject { group.to_s }
    it { expect(subject).to eq '#<Rbtype::Constants::Group ::MyClass (1 definitions)>' }
  end

  describe 'inspect' do
    let(:definitions) { [double('Definition', location: double(format: '/lib/test.rb:12'))] }
    subject { group.inspect }
    it { expect(subject).to eq '#<Rbtype::Constants::Group full_path=::MyClass definitions=[/lib/test.rb:12]>' }
  end

  describe 'size' do
    subject { group.size }
    it { expect(subject).to eq 0 }

    context 'with definitions' do
      let(:definitions) { [double('Definition')] }
      it { expect(subject).to eq 1 }
    end
  end

  describe '<<' do
    let(:definition) { double('Definition') }
    before { group << definition }
    subject { group }

    it { expect(subject.to_a).to eq [definition] }
  end

  describe 'each' do
    subject { group.each }
    it { expect(subject.class).to eq Enumerator }
  end

  describe 'empty?' do
    subject { group.empty? }
    it { expect(subject).to eq true }

    context 'with definitions' do
      let(:definitions) { [double('Definition')] }
      it { expect(subject).to eq false }
    end
  end

  describe 'any?' do
    subject { group.any? }
    it { expect(subject).to eq false }

    context 'with definitions' do
      let(:definitions) { [double('Definition')] }
      it { expect(subject).to eq true }
    end
  end

  describe 'concat' do
    let(:definitions) { [double('Definition', full_path: const_ref(:A))] }
    let(:more_definitions) { [double('Definition', full_path: const_ref(:B)), double('Definition', full_path: const_ref(:C))] }
    before { group.concat(more_definitions) }
    subject { group }
    it { expect(subject.size).to eq 3 }
    it { expect(subject.to_a).to eq [*definitions, *more_definitions] }
  end
end
