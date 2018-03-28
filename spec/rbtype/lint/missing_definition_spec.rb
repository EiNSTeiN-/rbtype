require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::MissingDefinition do
  let(:processed_source) { build_processed_source(source) }
  let(:sources) { [processed_source] }
  let(:runtime) { Rbtype::Runtime::Runtime.from_sources(sources) }
  let(:linter) { described_class.new(runtime) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'when a namespaced constant cannot be resolved' do
      let(:source) { <<~EOF }
        class A::B; end
        class A::C; end
      EOF
      it { expect(subject.size).to eq 2 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        Could not resolve `A` in context of `top_level` so declaration `A::B` was ignored
        - referenced in `class A::B; end` at test.rb:1
      ERR
      it { expect(subject[1].linter).to be linter }
      it { expect(subject[1].message).to eq <<~ERR }
        Could not resolve `A` in context of `top_level` so declaration `A::C` was ignored
        - referenced in `class A::C; end` at test.rb:2
      ERR
    end
  end
end
