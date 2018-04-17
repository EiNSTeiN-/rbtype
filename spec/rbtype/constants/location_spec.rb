require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::Location do
  let(:filename) { '/lib/test.rb' }
  let(:line) { 12 }
  let(:source_line) { 'class MyClass' }
  let(:loc) { described_class.new(filename, line, source_line) }

  describe 'format' do
    subject { loc.format }
    it { expect(subject).to eq "#{filename}:#{line}" }
  end

  describe 'backtrace_line' do
    subject { loc.backtrace_line }
    it { expect(subject).to eq "#{filename}:#{line} `#{source_line}`" }
  end

  describe 'to_s' do
    subject { loc.to_s }
    it { expect(subject).to eq "at #{filename}:#{line} `#{source_line}`" }
  end

  describe 'inspect' do
    subject { loc.inspect }
    it { expect(subject).to eq '#<Rbtype::Constants::Location filename="/lib/test.rb" line=12 source_line="class MyClass">' }
  end

  describe 'from_node' do
    let(:node) do
      double(
        location: double(
          expression: double(
            line: 32,
            source_line: '   class Foo::Bar',
            source_buffer: double(name: '/lib/my/file.rb')
          )
        )
      )
    end
    subject { described_class.from_node(node) }
    it { expect(subject.line).to eq 32 }
    it { expect(subject.source_line).to eq 'class Foo::Bar' }
    it { expect(subject.filename).to eq '/lib/my/file.rb' }
  end
end
