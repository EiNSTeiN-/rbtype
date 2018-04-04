require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::ExplicitBase do
  let(:require_locations) { [] }
  let(:processed_source) { build_processed_source(source) }
  let(:sources) { [processed_source] }
  let(:runtime) do
    runtime = Rbtype::Deps::RuntimeLoader.new(require_locations)
    runtime.load_sources(sources)
    runtime
  end
  let(:lint_constants) { [] }
  let(:lint_files) { ['test.rb'] }
  let(:linter) { described_class.new(runtime, constants: lint_constants, files: lint_files) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'when a class is defined with an explicit base on another class' do
      let(:source) { <<~EOF }
        class B
          class ::C
          end
        end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        `class ::C` at test.rb:2 was defined with an explicit base (::). The class or module is defined at the top level of the object hierarchy despite being located inside another class or module.
      ERR
    end

    context 'when a class is defined with an explicit base on the top level' do
      let(:source) { <<~EOF }
        class ::B
        end
      EOF
      it { expect(subject).to be_empty }
    end
  end
end
