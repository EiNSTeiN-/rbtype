require 'spec_helper'
require 'rbtype'

describe Rbtype::Deps::RailsAutoloadLocation do
  let(:path) { '/app/models' }
  let(:files) { ['/app/models/admin/test.rb'] }
  let(:loc) { described_class.new(path, files) }

  describe 'directory_exist?' do
    subject { loc.directory_exist?(name) }

    context 'when directory exists' do
      let(:name) { 'admin' }
      it { expect(subject).to be true }
    end

    context 'when directory does not exist' do
      let(:name) { 'no_such_dir' }
      it { expect(subject).to be false }
    end

    context 'when directory has same prefix' do
      let(:name) { 'adm' }
      it { expect(subject).to be false }
    end
  end
end
