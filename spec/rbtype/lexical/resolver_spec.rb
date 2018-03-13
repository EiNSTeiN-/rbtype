require 'spec_helper'
require 'rbtype'

describe Rbtype::Lexical::Resolver do
  let(:filename) { 'test.rb' }
  let(:buffer) do
    buffer = ::Parser::Source::Buffer.new(filename)
    buffer.source = source
    buffer
  end
  let(:processed_source) { Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24) }
  let(:lexical_context) { processed_source.lexical_context }
  let(:definitions) { lexical_context.definitions }
  subject { lexical_context }

  context 'finds class definitions' do
    let(:source) { 'class Foo; end; class Bar; end' }
    let(:foo) { definitions[0] }
    let(:bar) { definitions[1] }
    it { expect(definitions.size).to eq(2) }

    it { expect(foo.class).to eq(Rbtype::Lexical::ClassDefinition) }
    it { expect(foo.name_ref).to eq(const_ref(:Foo)) }
    it { expect(foo.nesting).to eq([foo, lexical_context]) }
    it { expect(foo.superclass_expr).to eq(nil) }

    it { expect(bar.class).to eq(Rbtype::Lexical::ClassDefinition) }
    it { expect(bar.name_ref).to eq(const_ref(:Bar)) }
    it { expect(bar.nesting).to eq([bar, lexical_context]) }
    it { expect(bar.superclass_expr).to eq(nil) }
  end

  context 'class with superclass' do
    let(:source) { 'class Foo < Bar; end' }
    let(:foo) { definitions[0] }
    it { expect(foo.class).to eq(Rbtype::Lexical::ClassDefinition) }
    it { expect(foo.name_ref).to eq(const_ref(:Foo)) }
    it { expect(foo.superclass_expr.const_reference).to eq(const_ref(:Bar)) }
  end

  context 'namespaced class' do
    let(:source) { 'class Foo::Bar; end' }
    let(:foo) { definitions[0] }
    it { expect(foo.class).to eq(Rbtype::Lexical::ClassDefinition) }
    it { expect(foo.name_ref).to eq(const_ref(:Foo, :Bar)) }
    it { expect(foo.nesting).to eq([foo, lexical_context]) }
    it { expect(foo.superclass_expr).to eq(nil) }
  end

  context 'root namespaced class' do
    let(:source) { 'class ::Foo::Bar; end' }
    let(:foo) { definitions[0] }
    it { expect(foo.class).to eq(Rbtype::Lexical::ClassDefinition) }
    it { expect(foo.name_ref).to eq(const_ref(nil, :Foo, :Bar)) }
    it { expect(foo.nesting).to eq([foo, lexical_context]) }
    it { expect(foo.superclass_expr).to eq(nil) }
  end

  context 'finds module definitions' do
    let(:source) { 'module Foo; end; module Bar; end' }
    let(:foo) { definitions[0] }
    let(:bar) { definitions[1] }
    it { expect(foo.class).to eq(Rbtype::Lexical::ModuleDefinition) }
    it { expect(foo.name_ref).to eq(const_ref(:Foo)) }
    it { expect(foo.superclass_expr).to eq(nil) }

    it { expect(bar.class).to eq(Rbtype::Lexical::ModuleDefinition) }
    it { expect(bar.name_ref).to eq(const_ref(:Bar)) }
    it { expect(bar.superclass_expr).to eq(nil) }
  end

  context 'namespaced module' do
    let(:source) { 'module Foo::Bar; end' }
    let(:bar) { definitions[0] }
    it { expect(bar.class).to eq(Rbtype::Lexical::ModuleDefinition) }
    it { expect(bar.name_ref).to eq(const_ref(:Foo, :Bar)) }
    it { expect(bar.nesting).to eq([bar, lexical_context]) }
    it { expect(bar.superclass_expr).to eq(nil) }
  end

  context 'namespaced nesting' do
    let(:source) { 'module Foo::Bar; module Baz; end end' }
    let(:bar) { definitions[0] }
    let(:baz) { bar.definitions[0] }
    it { expect(bar.class).to eq(Rbtype::Lexical::ModuleDefinition) }
    it { expect(baz.class).to eq(Rbtype::Lexical::ModuleDefinition) }
    it { expect(baz.nesting).to eq([baz, bar, lexical_context]) }
  end

  context 'root namespaced nesting' do
    let(:source) { 'module Foo::Bar; module ::Baz; end; end' }
    let(:bar) { definitions[0] }
    let(:baz) { bar.definitions[0] }
    it { expect(bar.class).to eq(Rbtype::Lexical::ModuleDefinition) }
    it { expect(baz.class).to eq(Rbtype::Lexical::ModuleDefinition) }
    it { expect(baz.nesting).to eq([baz, bar, lexical_context]) }
  end

  context 'finds method definitions' do
    let(:source) { 'def foo; end' }
    let(:foo) { definitions[0] }
    it { expect(foo.class).to eq(Rbtype::Lexical::MethodDefinition) }
    it { expect(foo.name_ref).to eq(:foo) }
    it { expect(foo.receiver_ref).to eq(nil) }
    it { expect(foo.superclass_expr).to eq(nil) }
  end

  context 'finds singleton method definitions' do
    let(:source) { 'def self.foo; end' }
    let(:foo) { definitions[0] }
    it { expect(foo.class).to eq(Rbtype::Lexical::MethodDefinition) }
    it { expect(foo.name_ref).to eq(:foo) }
    it { expect(foo.receiver_ref.class).to eq(Rbtype::Lexical::SelfReference) }
    it { expect(foo.superclass_expr).to eq(nil) }
  end

  context 'finds method definitions on object instances' do
    let(:source) { 'def object.foo; end' }
    let(:foo) { definitions[0] }
    it { expect(foo.class).to eq(Rbtype::Lexical::MethodDefinition) }
    it { expect(foo.name_ref).to eq(:foo) }
    it { expect(foo.receiver_ref.class).to eq(Rbtype::Lexical::ReceiverReference) }
    it { expect(foo.receiver_ref.to_s).to eq('object') }
    it { expect(foo.superclass_expr).to eq(nil) }
  end

  context 'finds method definitions on class' do
    let(:source) { 'def Foo.bar; end' }
    let(:foo) { definitions[0] }
    it { expect(foo.class).to eq(Rbtype::Lexical::MethodDefinition) }
    it { expect(foo.receiver_ref.class).to eq(Rbtype::Lexical::ConstReference) }
    it { expect(foo.name_ref).to eq(:bar) }
    it { expect(foo.receiver_ref).to eq(const_ref(:Foo)) }
    it { expect(foo.superclass_expr).to eq(nil) }
  end

  context 'nested definitions' do
    let(:source) { 'module Foo; class Bar; def bla; end; end; end' }
    let(:foo) { definitions[0] }
    let(:bar) { foo.definitions[0] }
    let(:bla) { bar.definitions[0] }

    it { expect(foo.class).to eq(Rbtype::Lexical::ModuleDefinition) }
    it { expect(foo.name_ref).to eq(const_ref(:Foo)) }
    it { expect(foo.superclass_expr).to eq(nil) }
    it { expect(foo.nesting).to eq([foo, lexical_context]) }

    it { expect(bar.class).to eq(Rbtype::Lexical::ClassDefinition) }
    it { expect(bar.name_ref).to eq(const_ref(:Bar)) }
    it { expect(bar.nesting).to \
      eq([bar, foo, lexical_context]) }

    it { expect(bla.class).to eq(Rbtype::Lexical::MethodDefinition) }
    it { expect(bla.name_ref).to eq(:bla) }
    it { expect(bla.nesting).to \
      eq([bar, foo, lexical_context]) }
  end

  context 'definitions know their parent' do
    let(:source) { 'module Foo; class Bar; end; end' }
    let(:foo) { definitions[0] }
    let(:bar) { foo.definitions[0] }
    it { expect(bar.nesting).to eq([
      bar,
      foo,
      lexical_context
    ]) }
  end

  context 'include into module' do
    let(:source) { 'module Foo; include Bar; end' }
    let(:foo) { definitions[0] }
    let(:bar) { foo.definitions[0] }

    it { expect(foo.class).to eq(Rbtype::Lexical::ModuleDefinition) }
    it { expect(bar.class).to eq(Rbtype::Lexical::IncludeReference) }
  end
end
