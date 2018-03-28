require 'spec_helper'
require 'rbtype'

describe Rbtype::Runtime::Runtime do
  let(:processed_source) { build_processed_source(content) }
  let(:sources) { [processed_source] }
  let(:runtime) { described_class.from_sources(sources) }

  describe 'from_sources' do
    context 'finds class A when defined' do
      subject { runtime.find_const(const_ref(:A)) }
      let(:content) { 'class A; end' }

      it { expect(subject.class).to eq Rbtype::Runtime::Class }
      it { expect(subject.name).to eq const_ref(:A) }
      it { expect(subject.type).to eq :class }
    end

    context 'finds module A when defined' do
      subject { runtime.find_const(const_ref(:A)) }
      let(:content) { 'module A; end' }

      it { expect(subject.class).to eq Rbtype::Runtime::Module }
      it { expect(subject.name).to eq const_ref(:A) }
      it { expect(subject.type).to eq :module }
    end

    context 'class can be defined multiple times' do
      let(:file1) { 'class A; end' }
      let(:file2) { 'class A; end' }
      let(:source1) { build_processed_source(file1, filename: 'test1.rb') }
      let(:source2) { build_processed_source(file2, filename: 'test2.rb') }
      let(:sources) { [source1, source2] }
      subject { runtime.find_const(const_ref(:A)) }

      it { expect(runtime.top_level.names).to eq [const_ref(:A)] }

      it { expect(subject.definitions.size).to eq 2 }
      it { expect(subject.definitions).to eq Set.new([
        *source1.lexical_context.definitions,
        *source2.lexical_context.definitions,
      ]) }
    end

    context 'when constant is undefined' do
      subject { runtime }
      let(:content) { 'class A::B; end' }

      it { expect(runtime.top_level.names).to eq [] }
      it { expect(runtime.delayed_definitions).to_not be_empty }
    end

    context 'undefined const is retyped when it comes into scope later' do
      let(:file1) { 'class A::B; end' }
      let(:file2) { 'class A; end' }
      let(:sources) { [build_processed_source(file1), build_processed_source(file2)] }
      subject { runtime }
      let(:a) { runtime.find_const(const_ref(:A)) }

      it { expect(a.class).to eq Rbtype::Runtime::Class }
      it { expect(a.name).to eq const_ref(:A) }
      it { expect(a.type).to eq :class }
    end

    context 'recursively defined nested classes' do
      let(:content) { 'class A; class B; end end' }
      subject { runtime }
      let(:a) { runtime.find_const(const_ref(:A)) }
      let(:b) { runtime.find_const(const_ref(:A, :B)) }

      it { expect(a.class).to eq Rbtype::Runtime::Class }
      it { expect(a.name).to eq const_ref(:A) }
      it { expect(a.type).to eq :class }

      it { expect(b.class).to eq Rbtype::Runtime::Class }
      it { expect(b.name).to eq const_ref(:B) }
      it { expect(b.type).to eq :class }
    end

    context 'nested classes with absolute path' do
      let(:content) { 'class A; class ::B; end end' }
      subject { runtime }
      let(:a) { runtime.find_const(const_ref(:A)) }
      let(:b) { runtime.find_const(const_ref(:B)) }

      it { expect(a.class).to eq Rbtype::Runtime::Class }
      it { expect(a.name).to eq const_ref(:A) }
      it { expect(a.type).to eq :class }

      it { expect(b.class).to eq Rbtype::Runtime::Class }
      it { expect(b.name).to eq const_ref(:B) }
      it { expect(b.type).to eq :class }
    end

    context 'nested classes defined on parent' do
      let(:content) { 'class A; class A::B; end end' }
      subject { runtime }
      let(:a) { runtime.find_const(const_ref(:A)) }
      let(:b) { runtime.find_const(const_ref(:A, :B)) }
      let(:delayed_definitions) { runtime.delayed_definitions }

      it { expect(delayed_definitions.size).to eq 0 }
      it { expect(subject.top_level.names).to eq [const_ref(:A)] }
      it { expect(a.names).to eq [const_ref(:B)] }

      it { expect(a.class).to eq Rbtype::Runtime::Class }
      it { expect(a.name).to eq const_ref(:A) }
      it { expect(a.type).to eq :class }

      it { expect(b.class).to eq Rbtype::Runtime::Class }
      it { expect(b.name).to eq const_ref(:B) }
      it { expect(b.type).to eq :class }
    end

    context 'nested classes defined on parent' do
      let(:content) { <<~EOF }
        class A
          class B
          end
        end
        class C
          class A::B::Z
          end
        end
      EOF
      subject { runtime }
      let(:a) { runtime.find_const(const_ref(:A)) }
      let(:ab) { runtime.find_const(const_ref(:A, :B)) }
      let(:abz) { runtime.find_const(const_ref(:A, :B, :Z)) }
      let(:c) { runtime.find_const(const_ref(:C)) }

      it { expect(subject.top_level.names).to eq [const_ref(:A), const_ref(:C)] }
      it { expect(a.names).to eq [const_ref(:B)] }
      it { expect(ab.names).to eq [const_ref(:Z)] }
      it { expect(abz.names).to eq [] }
      it { expect(c.names).to eq [] }
    end

    context 'nested classes defined on neighbour' do
      let(:content) { <<~EOF }
        class A
          class A; end
          class A::B; end
        end
      EOF
      subject { runtime }
      let(:a) { runtime.find_const(const_ref(:A)) }
      let(:aa) { runtime.find_const(const_ref(:A, :A)) }
      let(:ab) { runtime.find_const(const_ref(:A, :B)) }
      let(:aab) { runtime.find_const(const_ref(:A, :A, :B)) }

      it { expect(subject.top_level.names).to eq [const_ref(:A)] }

      it { expect(a.class).to eq Rbtype::Runtime::Class }
      it { expect(a.name).to eq const_ref(:A) }
      it { expect(a.type).to eq :class }

      it { expect(aa.class).to eq Rbtype::Runtime::Class }
      it { expect(aa.name).to eq const_ref(:A) }
      it { expect(aa.type).to eq :class }

      it { expect(ab).to eq nil }

      it { expect(aab.class).to eq Rbtype::Runtime::Class }
      it { expect(aab.name).to eq const_ref(:B) }
      it { expect(aab.type).to eq :class }
    end

    context 'conflicting definitions' do
      let(:file1) { 'class A; end' }
      let(:file2) { 'module A; end' }
      let(:source1) { build_processed_source(file1) }
      let(:source2) { build_processed_source(file2) }
      let(:sources) { [source1, source2] }
      subject { runtime }

      it { expect{ subject }.to raise_error(RuntimeError,
        'conflicting object redefinition: ::A is already defined as class instead of module') }
    end

    context 'optimisticly define unresolve constant in its lexical scope' do
      let(:content) { 'class A; class B::C; end end' }
      subject { runtime }
      let(:a) { runtime.find_const(const_ref(:A)) }

      it { expect(a.class).to eq Rbtype::Runtime::Class }
      it { expect(a.names).to eq [] }

      it { expect(runtime.delayed_definitions).to_not be_empty }
      it { expect(runtime.delayed_definitions[0].parent).to eq a }
      it { expect(runtime.delayed_definitions[0].definition.name_ref).to eq const_ref(:B, :C) }
    end

    context 'resolve ancestor class' do
      let(:content) { <<~EOF }
        class A; end
        class B < A; end
      EOF
      subject { runtime }
      let(:a) { runtime.find_const(const_ref(:A)) }
      let(:b) { runtime.find_const(const_ref(:B)) }

      it { expect(a.class).to eq Rbtype::Runtime::Class }
      it { expect(a.superclass).to eq nil }

      it { expect(b.class).to eq Rbtype::Runtime::Class }
      it { expect(b.superclass).to eq a }
    end

    context 'opaque class ancestor' do
      let(:content) { <<~EOF }
        class A < Struct.new
        end
      EOF
      subject { runtime }
      let(:a) { runtime.find_const(const_ref(:A)) }

      it { expect(a.class).to eq Rbtype::Runtime::Class }
      it { expect(a.superclass.class).to eq Rbtype::Runtime::OpaqueExpression }
      it { expect(a.superclass.type).to eq :opaque_expression }
      it { expect(a.superclass.expression.class).to eq Rbtype::Lexical::Expression }
    end

    context 'superclass in agreement' do
      let(:content) { <<~EOF }
        class A; end
        class B < A; end
        class B < A; end
      EOF
      subject { runtime }

      it { expect{ subject }.to_not raise_error }
    end

    context 'superclass missing from some definitions' do
      let(:content) { <<~EOF }
        class A; end
        class B; end
        class B < A; end
      EOF
      subject { runtime }

      it { expect{ subject }.to_not raise_error }
    end

    context 'superclass conflicts' do
      let(:content) { <<~EOF }
        class A; end
        class B; end
        class C < A; end
        class C < B; end
      EOF
      subject { runtime }

      it { expect{ subject }.to raise_error(RuntimeError,
        'Conflicting object superclass ::C was already defined '\
          'as #<Rbtype::Runtime::Class ::A> (in `class C < A; end`) at test.rb:3 '\
          'instead of #<Rbtype::Runtime::Class ::B> (in `class C < B; end`) at test.rb:4'\
        ) }
    end
  end
end
