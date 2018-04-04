require 'spec_helper'
require 'rbtype'

describe Rbtype::Deps::SpecLoader do
  let(:gemfile) { Bundler::SharedHelpers.default_gemfile }
  let(:lockfile) { Bundler::SharedHelpers.default_lockfile }
  let(:gems) { Rbtype::Deps::Gems.new(gemfile, lockfile) }
  let(:rbtype_spec) { gems.spec('rbtype') }
  let(:spec_loader) { described_class.new(rbtype_spec) }

  describe 'full_require_paths' do
    subject { spec_loader.full_require_paths }
    it { expect(subject.size).to eq 1 }
    it { expect(subject[0]).to eq File.expand_path(File.join(File.path(__FILE__), '../../../../lib')) }
  end
end
