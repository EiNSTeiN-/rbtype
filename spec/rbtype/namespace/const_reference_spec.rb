require 'spec_helper'
require 'rbtype'

describe Rbtype::Namespace::ConstReference do
  describe 'from_node' do
    let(:filename) { 'test.rb' }
    let(:buffer) do
      buffer = ::Parser::Source::Buffer.new(filename)
      buffer.source = source
      buffer
    end
    let(:processed_source) { Rbtype::ProcessedSource.new(buffer, ::Parser::Ruby24) }
    let(:ast) { processed_source.ast }
    let(:ref) { described_class.from_node(ast) }
    subject { ref }

    context 'const definition' do
      let(:source) { 'Foo' }
      it { expect(ast).to eq s(:const, nil, :Foo) }
      it { expect(subject.to_s).to eq 'Foo' }
      it { expect(subject.parts).to eq [:Foo] }
    end

    context 'namespaced const definition' do
      let(:source) { 'Foo::Bar' }
      it { expect(ast).to eq s(:const, s(:const, nil, :Foo), :Bar) }
      it { expect(subject.to_s).to eq 'Foo::Bar' }
      it { expect(subject.parts).to eq [:Foo, :Bar] }
      it { expect(subject.explicit_base?).to eq false }
    end

    context 'reference to top level method definition' do
      let(:source) { '::Foo::Bar' }
      it { expect(ast).to eq s(:const, s(:const, s(:cbase), :Foo), :Bar) }
      it { expect(subject.to_s).to eq '::Foo::Bar' }
      it { expect(subject.parts).to eq [nil, :Foo, :Bar] }
      it { expect(subject.explicit_base?).to eq true }
    end
  end

  describe '==' do
    it { expect(described_class.new([:Foo]) == described_class.new([:Foo])).to eq true }
    it { expect(described_class.new([:Foo]) == described_class.new([:Bar])).to eq false }
  end

  describe 'join' do
    subject { base.join(other) }

    context 'simple case' do
      let(:base) { described_class.new([:Foo]) }
      let(:other) { described_class.new([:Bar]) }

      it { expect(subject.to_s).to eq 'Foo::Bar' }
      it { expect(subject.parts).to eq [:Foo, :Bar] }
    end

    context 'when base is explicitly on cbase' do
      let(:base) { described_class.new([nil, :Foo]) }
      let(:other) { described_class.new([:Bar]) }

      it { expect(base.explicit_base?).to eq true }
      it { expect(subject.to_s).to eq '::Foo::Bar' }
      it { expect(subject.parts).to eq [nil, :Foo, :Bar] }
      it { expect(subject.explicit_base?).to eq true }
    end

    context 'when other is explicitly on cbase' do
      let(:base) { described_class.new([:Foo]) }
      let(:other) { described_class.new([nil, :Bar]) }

      it { expect(other.explicit_base?).to eq true }
      it { expect(subject.to_s).to eq '::Bar' }
      it { expect(subject.parts).to eq [nil, :Bar] }
      it { expect(subject.explicit_base?).to eq true }
    end

    context 'works when other is a simple array' do
      let(:base) { described_class.new([:Foo]) }
      let(:other) { [:Bar, :Baz] }

      it { expect(subject.to_s).to eq 'Foo::Bar::Baz' }
      it { expect(subject.parts).to eq [:Foo, :Bar, :Baz] }
    end
  end

  describe 'join!' do
    subject { base.join!(other) }

    context 'simple case' do
      let(:base) { described_class.new([:Foo]) }
      let(:other) { described_class.new([:Bar]) }

      it { expect(subject.to_s).to eq 'Foo::Bar' }
      it { expect(subject.parts).to eq [:Foo, :Bar] }
    end

    context 'when base is explicitly on cbase' do
      let(:base) { described_class.new([nil, :Foo]) }
      let(:other) { described_class.new([:Bar]) }

      it { expect(base.explicit_base?).to eq true }
      it { expect(subject.to_s).to eq '::Foo::Bar' }
      it { expect(subject.parts).to eq [nil, :Foo, :Bar] }
      it { expect(subject.explicit_base?).to eq true }
    end

    context 'when other is explicitly on cbase' do
      let(:base) { described_class.new([:Foo]) }
      let(:other) { described_class.new([nil, :Bar]) }

      it { expect(other.explicit_base?).to eq true }
      it { expect(subject.to_s).to eq '::Bar' }
      it { expect(subject.parts).to eq [nil, :Bar] }
      it { expect(subject.explicit_base?).to eq true }
    end

    context 'works when other is a simple array' do
      let(:base) { described_class.new([:Foo]) }
      let(:other) { [:Bar, :Baz] }

      it { expect(subject.to_s).to eq 'Foo::Bar::Baz' }
      it { expect(subject.parts).to eq [:Foo, :Bar, :Baz] }
    end
  end

  describe '[]' do
    context 'simple case' do
      let(:base) { described_class.new([:Foo, :Bar, :Baz]) }
      it { expect(base[0]).to eq described_class.new([:Foo]) }
      it { expect(base[1]).to eq described_class.new([:Bar]) }
      it { expect(base[2]).to eq described_class.new([:Baz]) }
      it { expect(base[3]).to eq nil }
    end

    context 'negative numbers' do
      let(:base) { described_class.new([:Foo, :Bar, :Baz]) }
      it { expect(base[-1]).to eq described_class.new([:Baz]) }
      it { expect(base[-2]).to eq described_class.new([:Bar]) }
      it { expect(base[-3]).to eq described_class.new([:Foo]) }
      it { expect(base[-4]).to eq nil }
    end

    context 'range' do
      let(:base) { described_class.new([:Foo, :Bar, :Baz]) }
      it { expect(base[0..1]).to eq described_class.new([:Foo, :Bar]) }
      it { expect(base[1..-1]).to eq described_class.new([:Bar, :Baz]) }
      it { expect(base[0..-2]).to eq described_class.new([:Foo, :Bar]) }
      it { expect(base[0..54]).to eq described_class.new([:Foo, :Bar, :Baz]) }
    end
  end

  describe 'in_bounds?' do
    let(:base) { described_class.new([:Foo, :Bar]) }
    it { expect(base.in_bounds?(0)).to eq true }
    it { expect(base.in_bounds?(1)).to eq true }
    it { expect(base.in_bounds?(2)).to eq false }
    it { expect(base.in_bounds?(-1)).to eq true }
    it { expect(base.in_bounds?(-2)).to eq true }
    it { expect(base.in_bounds?(-3)).to eq false }
  end
end
