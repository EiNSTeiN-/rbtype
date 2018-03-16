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
      let(:source1) { build_processed_source(file1) }
      let(:source2) { build_processed_source(file2) }
      let(:sources) { [source1, source2] }
      subject { runtime.find_const(const_ref(:A)) }

      it { expect(subject.definitions.size).to eq 2 }
      it { expect(subject.definitions).to eq [
        *source1.lexical_context.definitions,
        *source2.lexical_context.definitions,
      ] }
    end

    context 'declares undefined const A when defined through a usage' do
      subject { runtime }
      let(:content) { 'class A::B; end' }
      let(:a) { runtime.find_const(const_ref(:A)) }
      let(:b) { runtime.find_const(const_ref(:A, :B)) }

      it { expect(a.class).to eq Rbtype::Runtime::Undefined }
      it { expect(a.name).to eq const_ref(:A) }
      it { expect(a.type).to eq :undefined }

      it { expect(b.class).to eq Rbtype::Runtime::Class }
      it { expect(b.name).to eq const_ref(:B) }
      it { expect(b.type).to eq :class }
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

      it { expect(subject.names).to eq [const_ref(:A)] }

      it { expect(a.class).to eq Rbtype::Runtime::Class }
      it { expect(a.name).to eq const_ref(:A) }
      it { expect(a.type).to eq :class }

      it { expect(b.class).to eq Rbtype::Runtime::Class }
      it { expect(b.name).to eq const_ref(:B) }
      it { expect(b.type).to eq :class }
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

      it { expect(subject.names).to eq [const_ref(:A)] }

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
  end
end
