require 'spec_helper'
require 'rbtype'
require 'parser/ruby24'

describe Rbtype::Namespace::ConstAssignment do
  let(:nesting) { [const_ref(nil)] }
  let(:const_assignment) { described_class.from_node(ast, nesting: nesting) }
  subject { const_assignment }

  describe 'from_node' do
    let(:filename) { 'test.rb' }
    let(:buffer) do
      buffer = ::Parser::Source::Buffer.new(filename)
      buffer.source = source
      buffer
    end
    let(:processed_source) { Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24) }
    let(:ast) { processed_source.ast }

    context 'const definition' do
      let(:source) { '::Foo = 1' }
      it { expect(ast).to eq s(:casgn, s(:cbase), :Foo, s(:int, 1)) }
    end
  end

  describe 'value_type' do
    let(:ast) { s(:casgn, s(:cbase), :Foo, value_node) }
    subject { const_assignment.value_type }

    context 'const definition' do
      let(:value_node) { s(:int, 1) }
      it { expect(subject).to eq integer_instance_ref }
    end
  end
end
