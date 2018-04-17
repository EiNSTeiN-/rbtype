require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::Processor do
  let(:runtime_loader) { double('RuntimeLoader', db: runtime_db) }
  let(:processor) { Rbtype::Deps::Processor.new(source_set, require_locations, rails_autoload_locations) }
  let(:app_processed_source) { build_processed_source(source, filename: 'test.rb') }

end
