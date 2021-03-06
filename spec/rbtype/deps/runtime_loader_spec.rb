require 'spec_helper'
require 'rbtype'

describe Rbtype::Deps::RuntimeLoader do
  let(:require_locations) { [] }
  let(:rails_autoload_locations) { [] }
  let(:source_set) { Rbtype::SourceSet.new }
  let(:runtime_loader) { Rbtype::Deps::RuntimeLoader.new(source_set, require_locations, rails_autoload_locations) }
  let(:app_processed_source) { build_processed_source(source, filename: 'test.rb') }

  before do
    source_set << app_processed_source
  end

  describe 'requires' do
    subject do
      runtime_loader.load_source(app_processed_source)
      runtime_loader.db.requires
    end

    context 'file does not exist' do
      let(:source) { 'require "foo"' }
      subject do
        runtime_loader.load_source(app_processed_source)
        runtime_loader.require_failed
      end
      it { expect(subject).to_not be_empty }
      it { expect(subject.keys).to eq ['foo'] }
      it { expect(subject.values).to eq [runtime_loader.db.requires[0]] }
    end

    context 'file can be loaded from library' do
      let(:library_path) { '/lib' }
      let(:lib_processed_source) { build_processed_source(lib_source, filename: "#{library_path}/foo.rb") }
      let(:require_location) { Rbtype::Deps::RequireLocation.new(library_path, ["#{library_path}/foo.rb"]) }
      let(:require_locations) { [require_location] }

      let(:lib_source) { 'this_is_library' }
      let(:source) { 'require "foo"' }

      before do
        source_set << lib_processed_source
        source_set << app_processed_source
      end

      it { expect(subject).to_not be_empty }
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].class).to eq Rbtype::Constants::Requirement }
      it { expect(subject[0].relative_directory).to eq '.' }
      it { expect(subject[0].filename).to eq 'foo' }

      context 'required' do
        subject do
          runtime_loader.load_source(app_processed_source)
          runtime_loader.required
        end

        it { expect(subject).to_not be_empty }
        it { expect(subject.size).to eq 2 }
        it { expect(subject.keys.sort).to eq ["/lib/foo.rb", "test.rb"].sort }
      end
    end

    context 'require loop' do
      let(:library_path) { '/lib' }
      let(:lib1) { build_processed_source("require 'bar'", filename: "#{library_path}/foo.rb") }
      let(:lib2) { build_processed_source("require 'foo'", filename: "#{library_path}/bar.rb") }
      let(:require_location) { Rbtype::Deps::RequireLocation.new(library_path, [lib1.filename, lib2.filename]) }
      let(:require_locations) { [require_location] }

      let(:source) { 'require "foo"' }

      before do
        source_set << lib1
        source_set << lib2
      end

      it { expect(subject).to_not be_empty }
      it { expect(subject.size).to eq 3 }
      it { expect(subject[0].filename).to eq 'foo' }
      it { expect(subject[0].location.filename).to eq '/lib/bar.rb' }
      it { expect(subject[1].filename).to eq 'bar' }
      it { expect(subject[1].location.filename).to eq '/lib/foo.rb' }
      it { expect(subject[2].filename).to eq 'foo' }
      it { expect(subject[2].location.filename).to eq 'test.rb' }
    end
  end

  describe 'missings' do
    subject do
      runtime_loader.load_source(app_processed_source)
      runtime_loader.db.missings
    end

    context 'non existant name' do
      let(:source) { 'class Foo::Bar; end' }
      it { expect(subject).to_not be_empty }
      it { expect(subject.size).to eq 1 }
      it { expect(subject.keys).to eq [const_ref(nil, :Foo)] }
    end

    context 'initial constant is resolved through nesting but another is not found' do
      let(:source) { <<~EOF }
        class Foo
          class Foo::Bar::Baz; end
        end
      EOF
      it { expect(subject).to_not be_empty }
      it { expect(subject.size).to eq 2 }
      it { expect(subject.keys).to eq [const_ref(nil, :Foo, :Foo), const_ref(nil, :Foo, :Bar)] }
    end
  end

  describe 'definitions' do
    subject do
      runtime_loader.load_source(app_processed_source)
      runtime_loader.db.definitions
    end

    context 'simple module' do
      let(:source) { 'module Foo; end' }
      let(:foo_ref) { const_ref(nil, :Foo) }
      let(:foo_defs) { subject[foo_ref] }

      it { expect(subject.size).to eq 1 }
      it { expect(subject.keys).to eq [foo_ref] }

      it { expect(foo_defs).to_not be_nil }
      it { expect(foo_defs).to_not be_empty }
      it { expect(foo_defs.size).to eq 1 }

      it { expect(foo_defs[0].path).to eq const_ref(:Foo) }
      it { expect(foo_defs[0].name).to eq const_ref(:Foo) }
      it { expect(foo_defs[0].full_path).to eq foo_ref }
      it { expect(foo_defs[0].nesting).to eq [foo_defs[0]] }
    end

    context 'simple class' do
      let(:source) { 'class Foo; end' }
      let(:foo_ref) { const_ref(nil, :Foo) }
      let(:foo_defs) { subject[foo_ref] }

      it { expect(subject.size).to eq 1 }
      it { expect(subject.keys).to eq [foo_ref] }

      it { expect(foo_defs).to_not be_nil }
      it { expect(foo_defs).to_not be_empty }
      it { expect(foo_defs.size).to eq 1 }

      it { expect(foo_defs[0].path).to eq const_ref(:Foo) }
      it { expect(foo_defs[0].name).to eq const_ref(:Foo) }
      it { expect(foo_defs[0].full_path).to eq foo_ref }
      it { expect(foo_defs[0].nesting).to eq [foo_defs[0]] }
    end

    context 'define class with const base' do
      let(:source) { 'class ::Foo; end' }
      let(:foo_ref) { const_ref(nil, :Foo) }
      let(:foo_defs) { subject[foo_ref] }

      it { expect(subject.size).to eq 1 }
      it { expect(subject.keys).to eq [foo_ref] }

      it { expect(foo_defs).to_not be_nil }
      it { expect(foo_defs).to_not be_empty }
      it { expect(foo_defs.size).to eq 1 }

      it { expect(foo_defs[0].path).to eq const_ref(nil, :Foo) }
      it { expect(foo_defs[0].name).to eq const_ref(:Foo) }
      it { expect(foo_defs[0].full_path).to eq foo_ref }
      it { expect(foo_defs[0].nesting).to eq [foo_defs[0]] }
    end

    context 'nested class' do
      let(:source) { 'class Foo; class Bar; end end' }
      let(:foo_ref) { const_ref(nil, :Foo) }
      let(:bar_ref) { const_ref(nil, :Foo, :Bar) }
      let(:foo_defs) { subject[foo_ref] }
      let(:bar_defs) { subject[bar_ref] }

      it { expect(subject.size).to eq 2 }
      it { expect(subject.keys).to eq [foo_ref, bar_ref] }
      it { expect(bar_defs).to_not be_nil }
      it { expect(bar_defs).to_not be_empty }
      it { expect(bar_defs.size).to eq 1 }

      it { expect(bar_defs[0].path).to eq const_ref(:Bar) }
      it { expect(bar_defs[0].name).to eq const_ref(:Bar) }
      it { expect(bar_defs[0].full_path).to eq bar_ref }
      it { expect(bar_defs[0].nesting).to eq [bar_defs[0], foo_defs[0]] }
    end

    context 'using a class defined in same file' do
      let(:source) { <<~EOF }
        class Foo; end
        class Foo::Bar; end
      EOF
      let(:foo_defs) { subject[const_ref(nil, :Foo)] }
      let(:bar_defs) { subject[const_ref(nil, :Foo, :Bar)] }

      it { expect(subject.size).to eq 2 }
      it { expect(subject.keys).to eq [const_ref(nil, :Foo), const_ref(nil, :Foo, :Bar)] }
      it { expect(bar_defs).to_not be_nil }
      it { expect(bar_defs).to_not be_empty }
      it { expect(bar_defs.size).to eq 1 }

      it { expect(bar_defs[0].path).to eq const_ref(:Foo, :Bar) }
      it { expect(bar_defs[0].name).to eq const_ref(:Bar) }
      it { expect(bar_defs[0].full_path).to eq const_ref(nil, :Foo, :Bar) }
      it { expect(bar_defs[0].nesting).to eq [bar_defs[0]] }
    end

    context 'class reference of its own lexical parent' do
      let(:source) { <<~EOF }
        class Foo; class Foo::Bar; end end
      EOF
      let(:foo_defs) { subject[const_ref(nil, :Foo)] }
      let(:bar_defs) { subject[const_ref(nil, :Foo, :Bar)] }

      it { expect(subject.size).to eq 2 }
      it { expect(subject.keys).to eq [const_ref(nil, :Foo), const_ref(nil, :Foo, :Bar)] }
      it { expect(bar_defs).to_not be_nil }
      it { expect(bar_defs).to_not be_empty }
      it { expect(bar_defs.size).to eq 1 }

      it { expect(bar_defs[0].path).to eq const_ref(:Foo, :Bar) }
      it { expect(bar_defs[0].name).to eq const_ref(:Bar) }
      it { expect(bar_defs[0].full_path).to eq const_ref(nil, :Foo, :Bar) }
      it { expect(bar_defs[0].nesting).to eq [bar_defs[0], foo_defs[0]] }
    end

    context 'constants referenced in other files' do
      let(:library_path) { '/lib' }
      let(:lib1) { build_processed_source(foo_source, filename: "#{library_path}/foo.rb") }
      let(:require_location) { Rbtype::Deps::RequireLocation.new(library_path, [lib1.filename]) }
      let(:require_locations) { [require_location] }

      let(:foo_source) { 'class Foo; end' }
      let(:source) { <<~EOF }
        require 'foo'
        class Foo::Bar; end
      EOF

      let(:bar_defs) { subject[const_ref(nil, :Foo, :Bar)] }

      before do
        source_set << lib1
      end

      it { expect(subject.size).to eq 2 }
      it { expect(subject.keys).to eq [const_ref(nil, :Foo), const_ref(nil, :Foo, :Bar)] }
      it { expect(bar_defs).to_not be_nil }
      it { expect(bar_defs).to_not be_empty }
      it { expect(bar_defs.size).to eq 1 }

      it { expect(bar_defs[0].path).to eq const_ref(:Foo, :Bar) }
      it { expect(bar_defs[0].name).to eq const_ref(:Bar) }
      it { expect(bar_defs[0].full_path).to eq const_ref(nil, :Foo, :Bar) }
      it { expect(bar_defs[0].nesting).to eq [bar_defs[0]] }
    end
  end

  describe 'uses' do
    subject do
      runtime_loader.load_source(app_processed_source)
      runtime_loader.db.uses
    end

    context 'class reference of its own lexical parent' do
      let(:source) { <<~EOF }
        class Foo; class Foo::Bar; end end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject.keys).to eq [const_ref(nil, :Foo)] }

      context 'use of Foo' do
        let(:foo) { subject[const_ref(nil, :Foo)] }
        it { expect(foo.size).to eq 1 }
        it { expect(foo[0].class).to eq Rbtype::Constants::Use }
        it { expect(foo[0].full_path).to eq const_ref(nil, :Foo) }
        it { expect(foo[0].definitions.map(&:location).map(&:filename)).to eq ['test.rb'] }
      end
    end
  end
end
