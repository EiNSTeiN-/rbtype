require 'spec_helper'
require 'rbtype'

describe Rbtype::Lint::MissingConstant do
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
    context 'when class initially cannot be defined and is later defined' do
      let(:source) { <<~EOF }
        class A::C
        end
        class A
        end
      EOF
      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        `::A` could not be resolved when file test.rb was initially loaded, but the constant was later defined at test.rb:3. This can be resolved by adding a `require` statement in the first file or avoid the use of compact name to define classes.
      ERR
    end

    context 'when classes are resolved through nesting' do
      let(:source) { <<~EOF }
        class A
          class B
            class C
              class Z::D
              end
            end
          end
        end
        class Z; end
        class A::Z; end
        class A::B::Z; end
        class A::B::C::Z; end
      EOF
      it { expect(subject.size).to eq 4 }
      it { expect(subject[0].linter).to be linter }
      it { expect(subject[0].message).to eq <<~ERR }
        `::A::B::C::Z` could not be resolved when file test.rb was initially loaded, but the constant was later defined at test.rb:12. This can be resolved by adding a `require` statement in the first file or avoid the use of compact name to define classes.
      ERR
      it { expect(subject[1].message).to eq <<~ERR }
        `::A::B::Z` could not be resolved when file test.rb was initially loaded, but the constant was later defined at test.rb:11. This can be resolved by adding a `require` statement in the first file or avoid the use of compact name to define classes.
      ERR
      it { expect(subject[2].message).to eq <<~ERR }
        `::A::Z` could not be resolved when file test.rb was initially loaded, but the constant was later defined at test.rb:10. This can be resolved by adding a `require` statement in the first file or avoid the use of compact name to define classes.
      ERR
      it { expect(subject[3].message).to eq <<~ERR }
        `::Z` could not be resolved when file test.rb was initially loaded, but the constant was later defined at test.rb:9. This can be resolved by adding a `require` statement in the first file or avoid the use of compact name to define classes.
      ERR
    end
  end
end
