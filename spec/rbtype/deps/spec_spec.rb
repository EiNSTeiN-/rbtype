require 'spec_helper'
require 'rbtype'

describe Rbtype::Deps::Spec do
  let(:spec) { described_class.new(bundle_spec) }

  describe 'name' do
    let(:bundle_spec) { double('Gem::Spec', name: 'my-spec-name') }
    subject { spec.name }

    context 'delegates to spec' do
      it { expect(subject).to eq 'my-spec-name' }
    end
  end

  describe 'short_name' do
    let(:bundle_spec) { double('Gem::Spec', name: 'my-spec-name', version: '1.2.3') }
    subject { spec.short_name }

    context 'returns the spec name and version' do
      it { expect(subject).to eq '(my-spec-name @ 1.2.3)' }
    end
  end

  describe 'source_pathname' do
    let(:bundle_spec) { double('Gem::Spec', full_gem_path: '/full/path/to/my-gem') }
    subject { spec.source_pathname }

    context 'delegates to spec' do
      it { expect(subject).to eq '/full/path/to/my-gem' }
    end
  end

  describe 'full_require_paths' do
    subject { spec.full_require_paths }

    context 'delegates to spec' do
      let(:bundle_spec) { double('Gem::Spec', full_require_paths: ['foo']) }
      it { expect(subject).to eq ['foo'] }
    end

    context 'defaults to empty hash' do
      let(:bundle_spec) { double('Gem::Spec', full_require_paths: nil) }
      it { expect(subject).to eq [] }
    end
  end

  describe 'dependencies' do
    let(:dependencies) { [double('Gem::Dependency', name: 'active_support')] }
    let(:bundle_spec) { double('Gem::Spec', dependencies: dependencies) }
    subject { spec.dependencies }

    context 'delegates to spec' do
      it { expect(subject).to eq dependencies }
    end
  end

  describe 'require_locations' do
    let(:bundle_spec) { double('Gem::Spec', full_require_paths: ['/lib']) }
    subject { spec.require_locations }

    context 'when Dir[] globs regular files' do
      before do
        allow(File).to receive(:file?).with('/lib/test.rb').and_return(true)
        allow(Dir).to receive(:[]).with("/lib/**/*").and_return(['/lib/test.rb'])
      end

      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].class).to eq Rbtype::Deps::RequireLocation }
      it { expect(subject[0].path).to eq '/lib' }
      it { expect(subject[0].files).to eq Set.new(['/lib/test.rb']) }
    end

    context 'when Dir[] globs non regular files or directories' do
      before do
        allow(File).to receive(:file?).with('/lib/test.rb').and_return(false)
        allow(Dir).to receive(:[]).with("/lib/**/*").and_return(['/lib/test.rb'])
      end

      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].class).to eq Rbtype::Deps::RequireLocation }
      it { expect(subject[0].path).to eq '/lib' }
      it { expect(subject[0].files).to eq Set.new }
    end
  end
end
