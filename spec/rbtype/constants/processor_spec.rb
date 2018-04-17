require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::Processor do
  let(:runtime_db) { Rbtype::Constants::DB.new }
  let(:runtime_loader) do
    double('RuntimeLoader',
      db: runtime_db,
    )
  end
  let(:processor) { Rbtype::Deps::Processor.new(source_set, require_locations, rails_autoload_locations) }
  let(:processed_source) { build_processed_source(source, filename: 'test.rb') }
  let(:processor) { described_class.new(runtime_loader, processed_source) }

  before do
    allow(runtime_loader).to receive(:with_backtrace) do |line, &block|
      block.call
    end
  end

  describe 'db' do
    subject { processor.db }

    context 'new definition' do
      let(:source) { 'class Foo; end' }
      it { expect(subject.uses.size).to eq 0 }
      it { expect(subject.definitions.size).to eq 1 }
      it do
        expect_defined('::Foo')
        expect(definitions('::Foo').size).to eq 1
        foo = definitions('::Foo').first
        expect(foo.path).to eq const_ref(:Foo)
        expect(foo.name).to eq const_ref(:Foo)
        expect(foo.full_path).to eq const_ref(nil, :Foo)
        expect(foo.type).to eq :class
      end
    end

    context 'new nested definition' do
      let(:source) { <<~RUBY }
        class Foo
          class Bar
          end
        end
      RUBY
      it { expect(subject.uses.size).to eq 0 }
      it { expect(subject.definitions.size).to eq 2 }
      it do
        expect_defined('::Foo')
        expect(definitions('::Foo').size).to eq 1
        foo = definitions('::Foo').first
        expect(foo.nesting).to eq [foo]
        expect(foo.path).to eq const_ref(:Foo)
        expect(foo.full_path).to eq const_ref(nil, :Foo)
      end
      it do
        expect_defined('::Foo::Bar')
        expect(definitions('::Foo::Bar').size).to eq 1
        foo = definitions('::Foo').first
        bar = definitions('::Foo::Bar').first
        expect(bar.path).to eq const_ref(:Bar)
        expect(bar.full_path).to eq const_ref(nil, :Foo, :Bar)
        expect(bar.nesting).to eq [bar, foo]
      end
    end

    context 'new definition with compact namespace' do
      before do
        runtime_db.add_automatic_module(const_ref(nil, :Foo))
      end
      let(:source) { <<~RUBY }
        class Foo::Bar
        end
      RUBY
      it { expect(subject.uses.size).to eq 1 }
      it { expect(subject.definitions.size).to eq 1 }
      it do
        expect_used('::Foo')
        expect(uses('::Foo').size).to eq 1
        expect_defined('::Foo::Bar')
        expect(definitions('::Foo::Bar').size).to eq 1
        bar = definitions('::Foo::Bar').first
        expect(bar.path).to eq const_ref(:Foo, :Bar)
        expect(bar.full_path).to eq const_ref(nil, :Foo, :Bar)
        expect(bar.nesting).to eq [bar]
      end
    end

    private

    def expect_used(name)
      expect(uses(name)).to_not be_empty
    end

    def expect_defined(name)
      expect(definitions(name)).to_not be_empty
    end

    def definitions(name)
      ref = Rbtype::Constants::ConstReference.from_string(name)
      processor.db.definitions[ref]
    end

    def uses(name)
      ref = Rbtype::Constants::ConstReference.from_string(name)
      processor.db.uses[ref]
    end
  end
end
