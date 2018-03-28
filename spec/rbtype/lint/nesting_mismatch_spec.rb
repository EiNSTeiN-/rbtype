require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::NestingMismatch do
  let(:processed_source) { build_processed_source(source) }
  let(:sources) { [processed_source] }
  let(:runtime) { Rbtype::Runtime::Runtime.from_sources(sources) }
  let(:linter) { described_class.new(runtime) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'when definitions have different lexical nestings' do
      let(:source) { <<~EOF }
        class B
          class C; end
        end
        class B::C; end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        `C` at test.rb:2 has a lexical nesting [::B::C, ::B, ::], but another of its definition at test.rb:4 has a different lexical nesting [::B::C, ::]. This may cause unexpexted behavior because constant resolution in each location may find different results for the same constant name.
      ERR
    end

    context 'when definitions have the same lexical nestings' do
      let(:source) { <<~EOF }
        class B
          class C; end
        end
        class B
          class C; end
        end
      EOF
      it { expect(subject.size).to eq 0 }
    end
  end
end
