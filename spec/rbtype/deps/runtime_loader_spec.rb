require 'spec_helper'
require 'rbtype'

describe Rbtype::Deps::RuntimeLoader do
  let(:require_locations) { [] }
  let(:runtime_loader) { Rbtype::Deps::RuntimeLoader.new(require_locations) }
  let(:app_processed_source) { build_processed_source(source, filename: 'test.rb') }
  let(:processor) { described_class.new(runtime_loader, app_processed_source) }

  describe 'requires' do
    subject { processor.requires }

  end
end
