require 'spec_helper'
require 'rbtype'

describe Rbtype::Deps::RequireLocation do
  let(:path) { '/lib' }
  let(:files) { ['/lib/test.rb'] }
  let(:loc) { described_class.new(path, files) }

  describe 'to_s' do
    subject { loc.to_s }
    it { expect(subject).to eq '#<Rbtype::Deps::RequireLocation from /lib (1 files)>' }
  end

  describe 'inspect' do
    subject { loc.inspect }
    it { expect(subject).to eq '#<Rbtype::Deps::RequireLocation path="/lib" files=["/lib/test.rb"]>' }
  end

  describe 'path' do
    subject { loc.path }
    it { expect(subject).to eq '/lib' }

    context 'gets expanded' do
      let(:path) { '/lib/foo/../bar' }
      it { expect(subject).to eq '/lib/bar' }
    end
  end

  describe 'files' do
    subject { loc.files }
    it { expect(subject.class).to eq ::Set }
    it { expect(subject).to eq Set.new(['/lib/test.rb']) }

    context 'filenames get expanded' do
      let(:files) { ['/lib/foo/../bar/test.rb'] }
      it { expect(subject).to eq Set.new(['/lib/bar/test.rb']) }
    end
  end

  describe 'expand' do
    subject { loc.expand(name) }

    context 'relative name' do
      let(:name) { 'test.rb' }
      it { expect(subject).to eq '/lib/test.rb' }
    end

    context 'relative name with backtracking' do
      let(:name) { 'foo/../bar/test.rb' }
      it { expect(subject).to eq '/lib/bar/test.rb' }
    end

    context 'absolute name' do
      let(:name) { '/my/path/test.rb' }
      it { expect(subject).to eq '/my/path/test.rb' }
    end

    context 'absolute name with backtracking' do
      let(:name) { '/foo/../bar/test.rb' }
      it { expect(subject).to eq '/bar/test.rb' }
    end
  end

  describe 'find' do
    subject { loc.find(name) }

    context 'relative name' do
      let(:name) { 'test' }
      it { expect(subject).to eq '/lib/test.rb' }
    end

    context 'relative name with explicit extension' do
      let(:name) { 'test.rb' }
      it { expect(subject).to eq '/lib/test.rb' }
    end

    context 'relative name with backtracking' do
      let(:name) { 'foo/../test' }
      it { expect(subject).to eq '/lib/test.rb' }
    end

    context 'absolute name without extension' do
      let(:name) { '/lib/test' }
      it { expect(subject).to eq '/lib/test.rb' }
    end

    context 'absolute name with extension' do
      let(:name) { '/lib/test.rb' }
      it { expect(subject).to eq '/lib/test.rb' }
    end

    context 'absolute name with backtracking' do
      let(:name) { '/foo/../lib/test.rb' }
      it { expect(subject).to eq '/lib/test.rb' }
    end

    context 'can find .bundle files' do
      let(:files) { ['/lib/test.bundle'] }
      let(:name) { 'test' }
      it { expect(subject).to eq '/lib/test.bundle' }
    end

    context 'can find .so files' do
      let(:files) { ['/lib/test.so'] }
      let(:name) { 'test' }
      it { expect(subject).to eq '/lib/test.so' }
    end
  end
end
