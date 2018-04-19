require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::Location do
  let(:filename) { '/lib/test.rb' }
  let(:line) { 12 }
  let(:source_line) { '    class MyClass' }
  let(:range) do
    double(
      'Parser::Source::Range',
      line: line,
      source_line: source_line,
      source_buffer: double(name: filename),
    )
  end
  let(:loc) { described_class.new(range) }

  describe 'format' do
    subject { loc.format }
    it { expect(subject).to eq "#{filename}:#{line}" }
  end

  describe 'backtrace_line' do
    subject { loc.backtrace_line }
    it { expect(subject).to eq "#{filename}:#{line} `class MyClass`" }
  end

  describe 'to_s' do
    subject { loc.to_s }
    it { expect(subject).to eq "at #{filename}:#{line} `class MyClass`" }
  end

  describe 'inspect' do
    subject { loc.inspect }
    it { expect(subject).to eq '#<Rbtype::Constants::Location filename="/lib/test.rb" line=12 source_line="class MyClass">' }
  end

  describe 'from_node' do
    let(:node) { double(location: double(expression: range)) }
    subject { described_class.from_node(node) }
    it { expect(subject.line).to eq line }
    it { expect(subject.source_line).to eq 'class MyClass' }
    it { expect(subject.filename).to eq '/lib/test.rb' }
  end
end
