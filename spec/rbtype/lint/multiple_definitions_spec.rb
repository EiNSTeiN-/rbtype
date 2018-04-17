require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::MultipleDefinitions do
  let(:require_locations) { [] }
  let(:rails_autoload_locations) { [] }
  let(:processed_source) { build_processed_source(source) }
  let(:sources) { [processed_source] }
  let(:source_set) { Rbtype::SourceSet.new }
  let(:runtime) do
    runtime = Rbtype::Deps::RuntimeLoader.new(source_set, require_locations, rails_autoload_locations)
    runtime.load_sources(sources)
    runtime
  end
  let(:lint_constants) { [] }
  let(:linter) { described_class.new(runtime, constants: lint_constants, files: []) }
  before { linter.run }

  describe 'errors' do
    subject { linter.errors }
    context 'when a class has multiple definitions with relevant code' do
      let(:lint_constants) { [const_ref(nil, :B)] }
      let(:source) { <<~EOF }
        class B
          a()
        end
        class B
          b()
        end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        `::B` has multiple relevant definitions (not used for namespacing). This is not always an error, these classes or modules may be re-opened for monkey-patching, but it may also indicate a problem with your namespace. All definitions reproduced below:
        test.rb:1 `class B`
        test.rb:4 `class B`
      ERR
    end

    context 'when a class is reopened for namespacing' do
      let(:lint_constants) { [const_ref(nil, :B)] }
      let(:source) { <<~EOF }
        class B
          a()
        end
        class B
          class C
            b()
          end
        end
      EOF
      it { expect(subject).to be_empty }
    end
  end
end
