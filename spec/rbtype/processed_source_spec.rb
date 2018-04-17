require 'spec_helper'
require 'rbtype'

describe Rbtype::ProcessedSource do
  let(:source) { 'foo' }
  let(:filename) { 'test.rb' }
  let(:relative_to) { nil }
  let(:processed_source) { described_class.new(filename, source, ::Parser::Ruby24, relative_path: relative_to) }

  describe 'filename' do
    subject { processed_source }
    it { expect(subject.filename).to eq filename }
  end

  describe 'ast' do
    subject { processed_source.ast }
    it { expect(subject).to eq s(:send, nil, :foo) }
    it { expect(subject.class).to eq Rbtype::AST::Node }
  end

  describe '==' do
    subject { processed_source }
    it { expect(subject).to eq build_processed_source('foo', filename: 'test.rb') }
    it { expect(subject).to_not eq build_processed_source('foo', filename: 'not_test.rb') }
    it { expect(subject).to_not eq build_processed_source('bar', filename: 'test.rb') }
  end

  describe 'hash' do
    subject { processed_source.hash }
    it { expect(subject).to eq [source, filename].hash }
  end

  describe 'friendly_filename' do
    let(:filename) { '/home/user/src/lib/test.rb' }

    context 'when relative path is set' do
      let(:relative_to) { '/home/user/src' }
      subject { processed_source.friendly_filename }
      it { expect(subject).to eq 'lib/test.rb' }
    end

    context 'when relative path is nil' do
      let(:relative_to) { nil }
      subject { processed_source.friendly_filename }
      it { expect(subject).to eq filename }
    end
  end

  describe 'raw_content' do
    subject { processed_source.raw_content }
    it { expect(subject).to eq source }
  end

  describe 'to_s' do
    subject { processed_source.to_s }
    it { expect(subject).to eq '#<Rbtype::ProcessedSource test.rb>' }
  end

  describe 'inspect' do
    subject { processed_source.inspect }
    it { expect(subject).to eq '#<Rbtype::ProcessedSource file=test.rb>' }
  end
end
