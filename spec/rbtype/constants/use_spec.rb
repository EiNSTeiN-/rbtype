require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::Use do
  let(:full_path) { const_ref(nil, :MyNamespace, :MyClass) }
  let(:location) { Rbtype::Constants::Location.new("test.rb", 1, "class MyClass") }
  let(:use) { described_class.new(full_path, location) }

  describe 'to_s' do
    subject { use.to_s }
    it { expect(subject).to eq '#<Rbtype::Constants::Use ::MyNamespace::MyClass>' }
  end

  describe 'inspect' do
    subject { use.inspect }
    it { expect(subject).to eq '#<Rbtype::Constants::Use full_path=::MyNamespace::MyClass location=at test.rb:1 `class MyClass`>' }
  end
end
