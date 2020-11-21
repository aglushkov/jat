# frozen_string_literal: true

RSpec.describe Jat::JSON do
  describe '#dump' do
    it 'transforms data to json string' do
      data = { foo: :bar }
      expect(described_class.dump(data)).to eq '{"foo":"bar"}'
    end
  end
end
