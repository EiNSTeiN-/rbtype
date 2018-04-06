require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::LoadOrder do
  let(:require_locations) { [] }
  let(:rails_autoload_locations) { [] }
  let(:processed_source) { build_processed_source(source) }
  let(:sources) { [processed_source] }
  let(:runtime) do
    runtime = Rbtype::Deps::RuntimeLoader.new(require_locations, rails_autoload_locations)
    runtime.load_sources(sources)
    runtime
  end
  let(:lint_options) { { lint_all_files: true } }
  let(:linter) { described_class.new(runtime, **lint_options) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'when a class has multiple definitions with relevant code' do
      let(:lint_constants) { [const_ref(nil, :B)] }
      let(:source) { <<~EOF }
        class A
        end
        class B
          class A::C
          end
          class A
          end
        end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        `::A::C` may be load order dependant. One of its definitions at test.rb:4 resolves a constant `A` on the following nestings: [::B, ::] which initially caused this constant to be defined at `::A::C` but would now be defined at `::B::A::C`.
      ERR
    end
  end
end
