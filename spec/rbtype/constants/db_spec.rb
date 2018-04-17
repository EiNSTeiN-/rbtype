require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::DB do
  let(:db) { described_class.new }

  describe 'add_use' do
    let(:full_path) { const_ref(nil, :A) }
    let(:use) { double('Use', full_path: full_path) }
    before { db.add_use(use) }
    subject { db.uses }

    it { expect(subject.keys).to eq [full_path] }
    it { expect(subject[full_path].class).to eq Rbtype::Constants::Group }
    it { expect(subject[full_path].size).to eq 1 }
    it { expect(subject[full_path].to_a).to eq [use] }

    context 'when group exists' do
      let(:other_use) { double(full_path: full_path) }
      before { db.add_use(other_use) }
      it { expect(subject[full_path].size).to eq 2 }
      it { expect(subject[full_path].to_a).to eq [use, other_use] }
    end
  end

  describe 'add_definition' do
    let(:full_path) { const_ref(nil, :A) }
    let(:definition) { double('Definition', full_path: full_path) }
    before { db.add_definition(definition) }
    subject { db.definitions }

    it { expect(subject.keys).to eq [full_path] }
    it { expect(subject[full_path].class).to eq Rbtype::Constants::Group }
    it { expect(subject[full_path].size).to eq 1 }
    it { expect(subject[full_path].to_a).to eq [definition] }

    context 'when group exists' do
      let(:other_definition) { double(full_path: full_path) }
      before { db.add_definition(other_definition) }
      it { expect(subject[full_path].size).to eq 2 }
      it { expect(subject[full_path].to_a).to eq [definition, other_definition] }
    end
  end

  describe 'add_automatic_module' do
    let(:full_path) { const_ref(nil, :A) }
    before { db.add_automatic_module(full_path) }
    subject { db.definitions }

    context 'creates an empty definition group' do
      it { expect(subject.keys).to eq [full_path] }
      it { expect(subject[full_path].class).to eq Rbtype::Constants::Group }
      it { expect(subject[full_path].size).to eq 0 }
      it { expect(db.automatic_modules).to eq [full_path] }
    end

    context 'adding a new definition uses old group' do
      let(:definition) { double(full_path: full_path) }
      before { db.add_definition(definition) }
      it { expect(subject[full_path].size).to eq 1 }
      it { expect(subject[full_path].to_a).to eq [definition] }
      it { expect(db.automatic_modules).to eq [full_path] }
    end
  end

  describe 'add_missing_constant' do
    let(:full_path) { const_ref(nil, :A) }
    let(:missing_constant) { double('MissingConstant', full_path: full_path) }
    before { db.add_missing_constant(missing_constant) }
    subject { db.missings }

    it { expect(subject.keys).to eq [full_path] }
    it { expect(subject[full_path].class).to eq Rbtype::Constants::Group }
    it { expect(subject[full_path].size).to eq 1 }
    it { expect(subject[full_path].to_a).to eq [missing_constant] }

    context 'when group exists' do
      let(:other_missing_constant) { double(full_path: full_path) }
      before { db.add_missing_constant(other_missing_constant) }
      it { expect(subject[full_path].size).to eq 2 }
      it { expect(subject[full_path].to_a).to eq [missing_constant, other_missing_constant] }
    end
  end

  describe 'add_require' do
    let(:requirement) { double('Requirement') }
    before { db.add_require(requirement) }
    subject { db.requires }

    it { expect(subject.size).to eq 1 }
    it { expect(subject).to eq [requirement] }
  end

  describe 'merge' do
    let(:source_db) { described_class.new }
    let(:target_db) { described_class.new }

    before do
      target_db.add_use(double('Use', full_path: const_ref(:Foo)))
      target_db.add_definition(double('Definition', full_path: const_ref(:Foo, :Bar)))
      target_db.add_missing_constant(double('MissingConstant', full_path: const_ref(:Foo, :Bla)))
      target_db.add_require(double('Requirement', to_s: 'require "foo"'))
      target_db.add_automatic_module(const_ref(:Admin))

      source_db.add_use(double('Use', full_path: const_ref(:Bar)))
      source_db.add_definition(double('Definition', full_path: const_ref(:Bar, :Baz)))
      source_db.add_missing_constant(double('MissingConstant', full_path: const_ref(:Bar, :Bla)))
      source_db.add_require(double('Requirement', to_s: 'require "bar"'))
      target_db.add_automatic_module(const_ref(:Services))
    end
    subject { target_db.merge(source_db) }

    it { expect(subject).to be target_db }
    it { expect(subject.uses.size).to eq 2 }
    it { expect(subject.uses.keys).to eq [const_ref(:Foo), const_ref(:Bar)] }
    it { expect(subject.definitions.size).to eq 4 }
    it { expect(subject.definitions.keys).to eq [const_ref(:Foo, :Bar), const_ref(:Admin), const_ref(:Services), const_ref(:Bar, :Baz)] }
    it { expect(subject.missings.size).to eq 2 }
    it { expect(subject.missings.keys).to eq [const_ref(:Foo, :Bla), const_ref(:Bar, :Bla)] }
    it { expect(subject.requires.size).to eq 2 }
    it { expect(subject.requires.map(&:to_s)).to eq ['require "foo"', 'require "bar"'] }
    it { expect(subject.automatic_modules.size).to eq 2 }
    it { expect(subject.automatic_modules).to eq [const_ref(:Admin), const_ref(:Services)] }
  end
end
