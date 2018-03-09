require 'spec_helper'
require 'rbtype'

describe Rbtype::Namespace::Resolver do
  let(:filename) { 'test.rb' }
  let(:buffer) do
    buffer = ::Parser::Source::Buffer.new(filename)
    buffer.source = source
    buffer
  end
  let(:processed_source) { Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24) }
  let(:ast) { processed_source.ast }
  let(:context) { Rbtype::Namespace::Context.new }
  let(:resolver) { described_class.from_node(ast, context: context) }
  before { resolver }
  subject { context }

  context 'conditional declaration' do
    let(:source) { 'module Diff; end unless defined? Diff' }
  end

  context 'const assignment' do
    let(:source) { 'FOO = 1' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].name_ref).to eq(const_ref(:FOO)) }
    it { expect(resolver.resolve_definitions(const_ref(:FOO)).size).to eq(1) }
    it { expect(resolver.resolve_definitions(const_ref(:FOO))[0].class).to eq(Rbtype::Namespace::ConstAssignment) }
  end

  context 'top level const assignment' do
    let(:source) { '::FOO = 1' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].name_ref).to eq(const_ref(nil, :FOO)) }
    it { expect(resolver.resolve_definitions(const_ref(:FOO)).size).to eq(1) }
    it { expect(resolver.resolve_definitions(const_ref(:FOO))[0].class).to eq(Rbtype::Namespace::ConstAssignment) }
  end

  context 'const assignment with path' do
    let(:source) { 'FOO::BAR = 1' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].name_ref).to eq(const_ref(:FOO, :BAR)) }
    it { expect(resolver.resolve_definitions(const_ref(:FOO)).size).to eq(0) }
    it { expect(resolver.resolve_definitions(const_ref(:FOO, :BAR)).size).to eq(1) }
  end

  context 'const assignment inside class' do
    let(:source) { 'class Foo; BAR = 1; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo)).size).to eq(1) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo, :BAR)).size).to eq(1) }
  end

  context 'const assignment on top level from class' do
    let(:source) { 'class Foo; ::BAR = 1; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo)).size).to eq(1) }
    it { expect(resolver.resolve_definitions(const_ref(:BAR)).size).to eq(1) }
  end

  context 'finds class definitions' do
    let(:source) { 'class Foo; end; class Bar; end' }
    it { expect(subject.size).to eq(2) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ClassDefinition) }
    it { expect(subject[0].name_ref).to eq(const_ref(:Foo)) }
    it { expect(subject[0].nesting).to eq([const_ref(nil, :Foo), const_ref(nil)]) }
    it { expect(subject[0].superclass_expr).to eq(nil) }
    it { expect(subject[0].definition_path).to eq(const_ref(nil)) }
    it { expect(subject[0].definition_name).to eq(const_ref(:Foo)) }
    it { expect(subject[1].class).to eq(Rbtype::Namespace::ClassDefinition) }
    it { expect(subject[1].name_ref).to eq(const_ref(:Bar)) }
    it { expect(subject[1].nesting).to eq([const_ref(nil, :Bar), const_ref(nil)]) }
    it { expect(subject[1].superclass_expr).to eq(nil) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo))).to eq([subject[0]]) }
  end

  context 'finds multiple definitions with same name' do
    let(:source) { 'class Foo; end; module Foo; end' }
    it { expect(subject.size).to eq(2) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo)).size).to eq(2) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo))[0].class).to eq(Rbtype::Namespace::ClassDefinition) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo))[1].class).to eq(Rbtype::Namespace::ModuleDefinition) }
  end

  context 'finds multiple nested definitions with same name' do
    let(:source) { <<~RUBY }
      class Foo; end;
      module Any
        module ::Foo; end
      end
    RUBY
    it { expect(subject.size).to eq(2) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo)).size).to eq(2) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo))[0].class).to eq(Rbtype::Namespace::ClassDefinition) }
    it { expect(resolver.resolve_definitions(const_ref(:Foo))[1].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(resolver.resolve_definitions(const_ref(:Any, :Foo))).to eq(nil) }
  end

  context 'class with superclass' do
    let(:source) { 'class Foo < Bar; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ClassDefinition) }
    it { expect(subject[0].name_ref).to eq(const_ref(:Foo)) }
    it { expect(subject[0].superclass_expr.const_reference).to eq(const_ref(:Bar)) }
    it { expect(subject[0].definition_path).to eq(const_ref(nil)) }
    it { expect(subject[0].definition_name).to eq(const_ref(:Foo)) }
  end

  context 'namespaced class' do
    let(:source) { 'class Foo::Bar; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ClassDefinition) }
    it { expect(subject[0].name_ref).to eq(const_ref(:Foo, :Bar)) }
    it { expect(subject[0].nesting).to eq([const_ref(nil, :Foo, :Bar), const_ref(nil)]) }
    it { expect(subject[0].superclass_expr).to eq(nil) }
    it { expect(subject[0].definition_path).to eq(const_ref(nil, :Foo)) }
    it { expect(subject[0].definition_name).to eq(const_ref(:Bar)) }
  end

  context 'root namespaced class' do
    let(:source) { 'class ::Foo::Bar; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ClassDefinition) }
    it { expect(subject[0].name_ref).to eq(const_ref(nil, :Foo, :Bar)) }
    it { expect(subject[0].nesting).to eq([const_ref(nil, :Foo, :Bar), const_ref(nil)]) }
    it { expect(subject[0].superclass_expr).to eq(nil) }
    it { expect(subject[0].definition_path).to eq(const_ref(nil, :Foo)) }
    it { expect(subject[0].definition_name).to eq(const_ref(:Bar)) }
  end

  context 'finds module definitions' do
    let(:source) { 'module Foo; end; module Bar; end' }
    it { expect(subject.size).to eq(2) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(subject[0].name_ref).to eq(const_ref(:Foo)) }
    it { expect(subject[0].superclass_expr).to eq(nil) }
    it { expect(subject[0].definition_path).to eq(const_ref(nil)) }
    it { expect(subject[0].definition_name).to eq(const_ref(:Foo)) }
    it { expect(subject[1].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(subject[1].name_ref).to eq(const_ref(:Bar)) }
    it { expect(subject[1].superclass_expr).to eq(nil) }
  end

  context 'namespaced module' do
    let(:source) { 'module Foo::Bar; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(subject[0].name_ref).to eq(const_ref(:Foo, :Bar)) }
    it { expect(subject[0].nesting).to eq([const_ref(nil, :Foo, :Bar), const_ref(nil)]) }
    it { expect(subject[0].superclass_expr).to eq(nil) }
    it { expect(subject[0].definition_path).to eq(const_ref(nil, :Foo)) }
    it { expect(subject[0].definition_name).to eq(const_ref(:Bar)) }
  end

  context 'namespaced nesting' do
    let(:source) { 'module Foo::Bar; module Baz; end end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(subject[0].context[0].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(subject[0].context[0].nesting).to \
      eq([const_ref(nil, :Foo, :Bar, :Baz), const_ref(nil, :Foo, :Bar), const_ref(nil)]) }
    it { expect(subject[0].context[0].definition_path).to eq(const_ref(nil, :Foo, :Bar)) }
    it { expect(subject[0].context[0].definition_name).to eq(const_ref(:Baz)) }
  end

  context 'root namespaced nesting' do
    let(:source) { 'module Foo::Bar; module ::Baz; end; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(subject[0].context[0].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(subject[0].context[0].nesting).to eq([const_ref(nil, :Baz), const_ref(nil, :Foo, :Bar), const_ref(nil)]) }
    it { expect(subject[0].context[0].definition_path).to eq(const_ref(nil)) }
    it { expect(subject[0].context[0].definition_name).to eq(const_ref(:Baz)) }
  end

  context 'finds method definitions' do
    let(:source) { 'def foo; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::MethodDefinition) }
    it { expect(subject[0].name_ref).to eq(:foo) }
    it { expect(subject[0].receiver_ref).to eq(nil) }
    it { expect(subject[0].superclass_expr).to eq(nil) }
    it { expect(subject[0].definition_path).to eq(const_ref(nil)) }
    it { expect(subject[0].definition_name).to eq(const_ref(:foo)) }
  end

  context 'finds singleton method definitions' do
    let(:source) { 'def self.foo; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::MethodDefinition) }
    it { expect(subject[0].name_ref).to eq(:foo) }
    it { expect(subject[0].receiver_ref.class).to eq(Rbtype::Namespace::SelfReference) }
    it { expect(subject[0].superclass_expr).to eq(nil) }
  end

  context 'finds method definitions on object instances' do
    let(:source) { 'def object.foo; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::MethodDefinition) }
    it { expect(subject[0].name_ref).to eq(:foo) }
    it { expect(subject[0].receiver_ref.class).to eq(Rbtype::Namespace::ReceiverReference) }
    it { expect(subject[0].receiver_ref.to_s).to eq('object') }
    it { expect(subject[0].superclass_expr).to eq(nil) }
  end

  context 'finds method definitions on class' do
    let(:source) { 'def Foo.bar; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::MethodDefinition) }
    it { expect(subject[0].receiver_ref.class).to eq(Rbtype::Namespace::ConstReference) }
    it { expect(subject[0].name_ref).to eq(:bar) }
    it { expect(subject[0].receiver_ref.to_s).to eq('Foo') }
    it { expect(subject[0].superclass_expr).to eq(nil) }
    it { expect(subject[0].definition_path).to eq(const_ref(nil, :Foo)) }
    it { expect(subject[0].definition_name).to eq(const_ref(:bar)) }
  end

  context 'nested definitions' do
    let(:source) { 'module Foo; class Bar; def bla; end; end; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(subject[0].name_ref).to eq(const_ref(:Foo)) }
    it { expect(subject[0].superclass_expr).to eq(nil) }
    it { expect(subject[0].definition_path).to eq(const_ref(nil)) }
    it { expect(subject[0].definition_name).to eq(const_ref(:Foo)) }
    it { expect(subject[0].nesting).to eq([const_ref(nil, :Foo), const_ref(nil)]) }
    it { expect(subject[0].context.size).to eq(1) }
    it { expect(subject[0].context[0].class).to eq(Rbtype::Namespace::ClassDefinition) }
    it { expect(subject[0].context[0].name_ref).to eq(const_ref(:Bar)) }
    it { expect(subject[0].context[0].nesting).to \
      eq([const_ref(nil, :Foo, :Bar), const_ref(nil, :Foo), const_ref(nil)]) }
    it { expect(subject[0].context[0].definition_path).to eq(const_ref(nil, :Foo)) }
    it { expect(subject[0].context[0].definition_name).to eq(const_ref(:Bar)) }
    it { expect(subject[0].context[0].context.size).to eq(1) }
    it { expect(subject[0].context[0].context[0].class).to eq(Rbtype::Namespace::MethodDefinition) }
    it { expect(subject[0].context[0].context[0].name_ref).to eq(:bla) }
    it { expect(subject[0].context[0].context[0].nesting).to \
      eq([const_ref(nil, :Foo, :Bar), const_ref(nil, :Foo), const_ref(nil)]) }
    it { expect(subject[0].context[0].context[0].definition_path).to \
      eq(const_ref(nil, :Foo, :Bar)) }
    it { expect(subject[0].context[0].context[0].definition_name).to eq(const_ref(:bla)) }
  end

  context 'definitions know their parent' do
    let(:source) { 'module Foo; class Bar; end; end' }
    it { expect(subject[0].context[0].nesting).to eq([
      const_ref(nil, :Foo, :Bar),
      const_ref(nil, :Foo),
      const_ref(nil)
    ]) }
  end

  context 'include into module' do
    let(:source) { 'module Foo; include Bar; end' }
    it { expect(subject.size).to eq(1) }
    it { expect(subject[0].class).to eq(Rbtype::Namespace::ModuleDefinition) }
    it { expect(subject[0].context.size).to eq(1) }
    it { expect(subject[0].context[0].class).to eq(Rbtype::Namespace::IncludeReference) }
    it { expect(subject[0].include_references.size).to eq(1) }
    it { expect(subject[0].include_references[0].class).to eq(Rbtype::Namespace::IncludeReference) }
  end
end
