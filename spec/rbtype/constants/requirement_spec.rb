require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::Requirement do
  let(:node) do
    double(
      type: :send,
      children: [nil, :require, s(:str, 'foo')],
      location: double(
        expression: double(
          line: 32,
          source_line: 'require "foo"',
          source_buffer: double(name: '/lib/my/file.rb')
        )
      )
    )
  end
  let(:requirement) { described_class.new(node) }

  describe 'location' do
    subject { requirement.location }
    it { expect(subject.class).to eq Rbtype::Constants::Location }
    it { expect(subject.inspect).to eq '#<Rbtype::Constants::Location filename="/lib/my/file.rb" line=32 source_line="require \"foo\"">' }
  end

  describe 'relative_directory' do
    subject { requirement.relative_directory }
    it { expect(subject).to eq '/lib/my' }
  end

  describe 'method' do
    subject { requirement.method }
    it { expect(subject).to eq :require }
  end

  describe 'argument_node' do
    subject { requirement.argument_node }
    it { expect(subject).to eq s(:str, 'foo') }
  end

  describe 'string?' do
    subject { requirement.string? }
    it { expect(subject).to eq true }

    context 'when argument is not a string' do
      let(:node) { s(:send, nil, :require, s(:lvar, :foo)) }
      it { expect(subject).to eq false }
    end
  end

  describe 'filename' do
    subject { requirement.filename }
    it { expect(subject).to eq 'foo' }

    context 'when argument is not a string' do
      let(:node) { s(:send, nil, :require, s(:lvar, :foo)) }
      it { expect(subject).to eq nil }
    end
  end

  describe 'to_s' do
    subject { requirement.to_s }
    it { expect(subject).to eq '#<Rbtype::Constants::Requirement require "foo">' }
  end

  describe 'inspect' do
    subject { requirement.inspect }
    it { expect(subject).to eq '#<Rbtype::Constants::Requirement location=#<Rbtype::Constants::Location '\
      'filename="/lib/my/file.rb" line=32 source_line="require \\"foo\\""> resolved_filename=nil>' }
  end
end
