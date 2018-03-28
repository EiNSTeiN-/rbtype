require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::LoadOrder do
  let(:processed_source) { build_processed_source(source) }
  let(:sources) { [processed_source] }
  let(:runtime) { Rbtype::Runtime::Runtime.from_sources(sources) }
  let(:linter) { described_class.new(runtime) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'when a name is resolved but a conflicting name comes into definition later' do
      let(:source) { <<~EOF }
        class A; end
        class B
          class A::C; end
          class B::A; end
        end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        When the runtime representation was first loaded, `class A::C; end` at test.rb:3 was defined at ::A::C, but reloading the file would define it as ::B::A::C because ::B::A was defined later. This likely means this is a load-order dependant definition.To solve this issue, either avoid using a compact name altogether or use a compact name that includes cbase (`::A::C` or `::B::A::C`).
      ERR
    end
  end
end
