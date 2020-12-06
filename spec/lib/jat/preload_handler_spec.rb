# frozen_string_literal: true

RSpec.describe Jat::PreloadHandler do
  let(:service) { described_class }
  let(:jat) { Class.new(Jat) { type(:jat) } }
  let(:serializer) { jat.new }

  before { jat.config.auto_preload = true }

  it 'returns data when nil data provided' do
    data = nil
    result = service.(data, serializer)
    expect(result).to equal data
  end

  it 'returns data when empty Array provided' do
    data = []
    result = service.(data, serializer)

    expect(result).to equal data
  end

  it 'returns data when serializer preloads are empty' do
    data = [1, 2, 3]
    result = service.(data, serializer)

    expect(result).to equal data
  end

  it "raises error when can't preload to provided data" do
    handler = Class.new do
      def self.fit?(_); false; end
      def self.preload(obj, _); obj; end
    end
    stub_const("#{described_class}::HANDLERS", [handler])

    serializer.class.attribute :foo, preload: :foo
    expect { service.('DATA', serializer) }.to raise_error(Jat::Error, /preload/)
  end

  it 'returns data with preloads' do
    handler = Class.new do
      def self.fit?(_); true; end
      def self.preload(_, _); 'DATA_WITH_PRELOADS'; end
    end
    stub_const("#{described_class}::HANDLERS", [handler])

    serializer.class.attribute :foo, preload: :foo
    result = service.('DATA', serializer)

    expect(result).to eq 'DATA_WITH_PRELOADS'
  end
end
