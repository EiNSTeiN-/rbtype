require 'spec_helper'
require 'rbtype'

describe Rbtype::Deps::Gems do
  let(:gemfile) { Bundler::SharedHelpers.default_gemfile }
  let(:lockfile) { Bundler::SharedHelpers.default_lockfile }
  let(:gems) { described_class.new(gemfile, lockfile) }
  subject { gems }

  describe 'spec_by_name' do
    context 'can get a list of dependencies' do
      it { expect(subject.spec('rbtype').name).to eq 'rbtype' }
      it { expect(subject.spec('bumblebee')).to eq nil }
    end
  end

  describe 'requires' do
    context 'has dependent gems' do
      it { expect(subject.requires).to include 'rbtype' }
    end
  end

  describe 'ordered_requires' do
    context 'has dependent gems' do
      it { expect(subject.ordered_requires).to include 'rbtype' }
    end
  end
end
