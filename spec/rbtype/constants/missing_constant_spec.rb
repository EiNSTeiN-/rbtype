require 'spec_helper'
require 'rbtype'

describe Rbtype::Constants::MissingConstant do
  let(:full_path) { const_ref(nil, :MyNamespace, :MyClass) }
  let(:location) { Rbtype::Constants::Location.new("test.rb", 1, "class MyClass") }
  let(:missing_constant) { described_class.new(full_path, location) }

  describe 'name' do
    subject { missing_constant.name }
    it { expect(subject).to eq const_ref(:MyClass) }
  end

  describe 'to_s' do
    subject { missing_constant.to_s }
    it { expect(subject).to eq '#<Rbtype::Constants::MissingConstant ::MyNamespace::MyClass>' }
  end

  describe 'inspect' do
    subject { missing_constant.inspect }
    it { expect(subject).to eq '#<Rbtype::Constants::MissingConstant full_path=::MyNamespace::MyClass location=at test.rb:1 `class MyClass`>' }
  end
end
