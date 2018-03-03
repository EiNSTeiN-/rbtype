require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::ConflictingDefinition do
  let(:filename) { 'test.rb' }
  let(:buffer) do
    buffer = ::Parser::Source::Buffer.new(filename)
    buffer.source = source
    buffer
  end
  let(:processed_source) { Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24) }
  let(:ast) { processed_source.ast }
  let(:context) { Rbtype::Namespace::Context.new }
  let(:resolver) { Rbtype::Namespace::Resolver.from_node(ast, context: context) }
  let(:linter) { described_class.new(resolver) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'both a class and a module' do
      let(:source) { <<~EOF }
        class A; end
        module A; end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq "Conflicting definitions for ::A (see test.rb:1, test.rb:2)" }
    end

    context 'both a class and a const' do
      let(:source) { <<~EOF }
        class A; end
        A = 1
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq "Conflicting definitions for ::A (see test.rb:1, test.rb:2)" }
    end

    context 'a const defined at top level' do
      let(:source) { <<~EOF }
        class A; end
        module B
          ::A = 2
        end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq "Conflicting definitions for ::A (see test.rb:1, test.rb:3)" }
    end

    context 'specified and missing ancestor' do
      let(:source) { <<~EOF }
        class A; end
        class B < A; end
        class B; end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~EOF.strip }
        Conflicting ancestors for `::B` were resolved to:
        - ::A at test.rb:2
        - (no parent) at test.rb:3
      EOF
    end

    context 'multiple specified ancestor' do
      let(:source) { <<~EOF }
        class A; end
        class C; end
        class B < A; end
        class B < C; end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~EOF.strip }
        Conflicting ancestors for `::B` were resolved to:
        - ::A at test.rb:3
        - ::C at test.rb:4
      EOF
    end

    context 'resolved and unresolved ancestor' do
      let(:source) { <<~EOF }
        class A; end
        class B < A; end
        class B < C; end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~EOF.strip }
        Conflicting ancestors for `::B` were resolved to:
        - ::A at test.rb:2
        - (not resolved C) at test.rb:3
      EOF
    end

    context 'same name but different resolved ancestors' do
      let(:source) { <<~EOF }
        class A; end
        module Z
          class A; end
        end
        module Z
          class B < A; end
        end
        class Z::B < A; end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~EOF.strip }
        Conflicting ancestors for `::Z::B` were resolved to:
        - ::Z::A at test.rb:6
        - ::A at test.rb:8
      EOF
    end

    context 'resolved non conflicting acestors' do
      let(:source) { <<~EOF }
        class A; end
        module Z
          class A; end
          class B < ::A; end
        end
        class Z::B < A; end
      EOF
      it { expect(subject.size).to eq 0 }
    end
  end
end
