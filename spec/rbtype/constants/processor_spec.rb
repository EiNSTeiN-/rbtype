require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::Processor do
  let(:runtime_db) { Rbtype::Constants::DB.new }
  let(:runtime_loader) do
    double('RuntimeLoader',
      db: runtime_db,
    )
  end
  let(:diagnostics) { [] }
  let(:processor) { Rbtype::Deps::Processor.new(source_set, require_locations, rails_autoload_locations) }
  let(:processed_source) { build_processed_source(source, filename: 'test.rb') }
  let(:processor) { described_class.new(runtime_loader, processed_source) }

  before do
    allow(runtime_loader).to receive(:raise_with_backtrace!) { |e| raise e }
    allow(runtime_loader).to receive(:with_backtrace) do |line, &block|
      block.call
    end
    allow(runtime_loader).to receive(:diag) { |*args| diagnostics << args }
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

    context 'new definition with compact namespace referencing valid module' do
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

    context 'missing constants' do
      before { allow(runtime_loader).to receive(:autoload_constant).and_return(nil) }
      let(:source) { <<~RUBY }
        class Foo::Bar
        end
      RUBY
      it { expect(subject.uses.size).to eq 0 }
      it { expect(subject.definitions.size).to eq 0 }
      it do
        expect_missing('::Foo')
        expect(missings('::Foo').size).to eq 1
        foo = missings('::Foo').first
        expect(foo.full_path).to eq const_ref(nil, :Foo)
      end
    end

    context 'missing constant in nested class' do
      before { allow(runtime_loader).to receive(:autoload_constant).and_return(nil) }
      let(:source) { <<~RUBY }
        class Foo
          class Bar
            class A::B; end
          end
        end
      RUBY
      it { expect(subject.uses.size).to eq 0 }
      it { expect(subject.definitions.size).to eq 2 }
      it { expect(subject.missings.size).to eq 3 }
      it 'creates missing constants reference at each level' do
        expect_missing('::Foo::Bar::A')
        expect_missing('::Foo::A')
        expect_missing('::A')
      end
    end

    context 'missing constant in nested class' do
      before { allow(runtime_loader).to receive(:autoload_constant).and_return(nil) }
      let(:source) { <<~RUBY }
        class Foo
          class Bar
            class A::B; end
          end
        end
      RUBY
      it { expect(subject.uses.size).to eq 0 }
      it { expect(subject.definitions.size).to eq 2 }
      it { expect(subject.missings.size).to eq 3 }
      it 'creates missing constants reference at each level' do
        expect_missing('::Foo::Bar::A')
        expect_missing('::Foo::A')
        expect_missing('::A')
      end
    end

    context 'initial constant resolved through nesting, then absolute' do
      before { allow(runtime_loader).to receive(:autoload_constant).and_return(nil) }
      let(:source) { <<~RUBY }
        class Foo
          class A; end
          class Bar
            class A::B; end
          end
        end
      RUBY
      it { expect(subject.uses.size).to eq 1 }
      it { expect(subject.definitions.size).to eq 4 }
      it { expect(subject.missings.size).to eq 1 }
      it do
        expect_defined('::Foo')
        expect_defined('::Foo::A')
        expect_defined('::Foo::A::B')
        expect_defined('::Foo::Bar')
        expect_used('::Foo::A')
        expect_missing('::Foo::Bar::A')
      end
    end

    context 'require statement' do
      before do
        allow(runtime_loader).to receive(:process_requirement).and_return('/lib/my/file.rb')
      end

      context 'require' do
        let(:source) { <<~RUBY }
          require "my/file"
        RUBY
        it { expect(subject.uses.size).to eq 0 }
        it { expect(subject.definitions.size).to eq 0 }
        it { expect(subject.requires.size).to eq 1 }
        it do
          req = subject.requires[0]
          expect(req.method).to eq :require
          expect(req.argument_node).to eq s(:str, 'my/file')
          expect(req.filename).to eq 'my/file'
          expect(req.resolved_filename).to eq '/lib/my/file.rb'
        end
      end

      context 'require_relative' do
        let(:source) { <<~RUBY }
          require_relative "my/file"
        RUBY
        it { expect(subject.uses.size).to eq 0 }
        it { expect(subject.definitions.size).to eq 0 }
        it { expect(subject.requires.size).to eq 1 }
        it do
          req = subject.requires[0]
          expect(req.method).to eq :require_relative
          expect(req.argument_node).to eq s(:str, 'my/file')
          expect(req.filename).to eq 'my/file'
          expect(req.resolved_filename).to eq '/lib/my/file.rb'
        end
      end

      context 'require_dependency' do
        let(:source) { <<~RUBY }
          require_dependency "my/file"
        RUBY
        it { expect(subject.uses.size).to eq 0 }
        it { expect(subject.definitions.size).to eq 0 }
        it { expect(subject.requires.size).to eq 1 }
        it do
          req = subject.requires[0]
          expect(req.method).to eq :require_dependency
          expect(req.argument_node).to eq s(:str, 'my/file')
          expect(req.filename).to eq 'my/file'
          expect(req.resolved_filename).to eq '/lib/my/file.rb'
        end
      end
    end

    context 'unreachable constant because of nesting' do
      before { allow(runtime_loader).to receive(:autoload_constant).and_return(nil) }
      let(:source) { <<~RUBY }
        class Foo
          class A
          end
        end
        class Foo::Bar
          class A::B
          end
        end
      RUBY
      it { expect(subject.uses.size).to eq 1 }
      it { expect(subject.definitions.size).to eq 3 }
      it { expect(subject.missings.size).to eq 2 }
      it do
        expect_defined('::Foo')
        expect_defined('::Foo::Bar')
        expect_used('::Foo')
        expect_missing('::Foo::Bar::A')
        expect_missing('::A')
      end
    end

    context 'unreachable constant because of nesting' do
      before { allow(runtime_loader).to receive(:autoload_constant).and_return(nil) }
      let(:source) { <<~RUBY }
        class Foo
          class A
          end
        end
        class Foo::Bar
          class A::B
          end
        end
      RUBY
      it { expect(subject.uses.size).to eq 1 }
      it { expect(subject.definitions.size).to eq 3 }
      it { expect(subject.missings.size).to eq 2 }
      it do
        expect_defined('::Foo')
        expect_defined('::Foo::Bar')
        expect_used('::Foo')
        expect_missing('::Foo::Bar::A')
        expect_missing('::A')
      end
    end

    context 'constant is autoloaded from runtime in last resort' do
      let(:autoloaded) do
        double('Group',
          full_path: const_ref(nil, :Foo, :Bar, :A)
        )
      end
      before do
        allow(runtime_loader).to receive(:autoload_constant).with(const_ref(nil, :A)).and_return(autoloaded)
      end
      let(:source) { <<~RUBY }
        class A::B; end
      RUBY
      it { expect(subject.uses.size).to eq 1 }
      it { expect(subject.definitions.size).to eq 1 }
      it { expect(subject.missings.size).to eq 0 }
      it do
        expect_used('::Foo::Bar::A')
        expect_defined('::Foo::Bar::A::B')
      end
    end

    private

    def expect_used(name)
      expect(uses(name)).to_not be_empty
    end

    def expect_defined(name)
      expect(definitions(name)).to_not be_empty
    end

    def expect_missing(name)
      expect(missings(name)).to_not be_empty
    end

    def definitions(name)
      ref = Rbtype::Constants::ConstReference.from_string(name)
      processor.db.definitions[ref]
    end

    def uses(name)
      ref = Rbtype::Constants::ConstReference.from_string(name)
      processor.db.uses[ref]
    end

    def missings(name)
      ref = Rbtype::Constants::ConstReference.from_string(name)
      processor.db.missings[ref]
    end
  end
end
