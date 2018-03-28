require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::LexicalPathMismatch do
  let(:processed_source) { build_processed_source(source) }
  let(:sources) { [processed_source] }
  let(:runtime) { Rbtype::Runtime::Runtime.from_sources(sources) }
  let(:linter) { described_class.new(runtime) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'when a name is defined on its own lexical parent' do
      let(:source) { <<~EOF }
        class B
          class B::C; end
        end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        `class B::C; end` at test.rb:2 was defined at `::B::C`, but its lexical definition indicates it should be  defined at `::B::B::C` instead. This occurs when a compact name is used to define a constant and its name resolves to an unepxected location. Inspect the following location(s):
        - class B::C; end at test.rb:2
      ERR
    end

    context 'when a name is defined on an unrelated class' do
      let(:source) { <<~EOF }
        class A; end
        class B
          class C; end
          class C::D
            class A::C; end
          end
        end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        `class A::C; end` at test.rb:5 was defined at `::A::C`, but its lexical definition indicates it should be  defined at `::B::C::D::A::C` instead. This occurs when a compact name is used to define a constant and its name resolves to an unepxected location. Inspect the following location(s):
        - class A::C; end at test.rb:5
        - class C::D at test.rb:4
      ERR
    end
  end
end
