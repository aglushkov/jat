# frozen_string_literal: true

RSpec.describe Jat::Opts do
  let(:jat) { Class.new(Jat) }

  let(:opts) { described_class.new(jat, name, data, original_block) }
  let(:name) { :name }
  let(:data) { {} }
  let(:original_block) { nil }

  describe '#name' do
    subject(:new_name) { opts.name }

    let(:name) { 'foo' }

    it 'symbolizes name' do
      expect(new_name).to eq :foo
    end
  end

  describe '#key' do
    subject(:key) { opts.key }

    let(:name) { 'foo' }

    context 'when no key provided' do
      it 'defaults to name' do
        expect(key).to eq :foo
      end
    end

    context 'when key provided' do
      let(:data) { { key: 'foo_key' } }

      it 'returns symbolized data key' do
        expect(key).to eq :foo_key
      end
    end
  end

  describe '#delegate?' do
    subject(:is_delegate) { opts.delegate? }

    before { jat.options[:delegate] = true }

    context 'when no key provided' do
      it 'defaults to serializer delegate option' do
        expect(is_delegate).to eq true
      end
    end

    context 'when key provided' do
      let(:data) { { delegate: false } }

      it 'returns provided value' do
        expect(is_delegate).to eq false
      end
    end
  end

  describe '#exposed?' do
    subject(:is_exposed) { opts.exposed? }

    context 'when key provided' do
      let(:data) { { exposed: false } }

      it 'returns provided value' do
        expect(is_exposed).to eq false
      end
    end

    context 'when all keys are exposed' do
      before { jat.options[:exposed] = :all }

      it 'returns true' do
        expect(is_exposed).to eq true
      end
    end

    context 'when no keys are exposed' do
      before { jat.options[:exposed] = :none }

      it 'returns false' do
        expect(is_exposed).to eq false
      end
    end

    context 'with serializer by default' do
      before { jat.options[:exposed] = :default }

      let(:data) { { serializer: jat } }

      it 'returns false when has serializer' do
        expect(is_exposed).to eq false
      end
    end

    context 'without serializer by default' do
      before { jat.options[:exposed] = :default }

      let(:data) { {} }

      it 'returns true' do
        expect(is_exposed).to eq true
      end
    end
  end

  describe '#many?' do
    subject(:is_many) { opts.many? }

    context 'when no key provided' do
      it 'defaults to false' do
        expect(is_many).to eq false
      end
    end

    context 'when key provided' do
      let(:data) { { many: true } }

      it 'returns provided data' do
        expect(is_many).to eq true
      end
    end
  end

  describe '#relation?' do
    subject(:is_relation) { opts.relation? }

    context 'when no serializer key' do
      it 'returns false' do
        expect(is_relation).to eq false
      end
    end

    context 'with serializer key' do
      let(:data) { { serializer: jat } }

      it 'returns true' do
        expect(is_relation).to eq true
      end
    end
  end

  describe '#serializer' do
    subject(:serializer) { opts.serializer }

    context 'when no serializer key' do
      it 'returns nil' do
        expect(serializer).to eq nil
      end
    end

    context 'with serializer key' do
      let(:data) { { serializer: jat } }

      it 'returns provided serializer' do
        expect(serializer).to eq jat
      end
    end

    context 'with serializer key as callable' do
      let(:data) { { serializer: -> { jat } } }

      it 'returns provided serializer' do
        expect(serializer).to eq jat
      end
    end

    context 'when callable serializer returns not a Jat serializer class' do
      let(:data) { { serializer: -> { nil } } }

      it 'raises error' do
        expect { serializer }.to raise_error Jat::Error, /must be a subclass of Jat/
      end
    end
  end

  describe '#includes' do
    subject(:includes) { opts.includes }

    context 'when no data provided and no serializer' do
      it 'returns nil' do
        expect(includes).to eq nil
      end
    end

    context 'when data provided' do
      let(:data) { { includes: { some: :data } } }

      it 'returns transformed hash' do
        expect(includes).to eq(some: { data: {} })
      end
    end

    context 'when no data provided and serializer exists' do
      let(:data) { { serializer: jat } }

      it 'generates hash from current key' do
        allow(opts).to receive(:key).and_return(:foobar)

        expect(includes).to eq(foobar: {})
      end
    end

    context 'when data provided and serializer exists' do
      let(:data) { { includes: :data } }

      it 'returns transformed hash' do
        expect(includes).to eq(data: {})
      end
    end
  end

  describe '#block' do
    subject(:block) { opts.block }

    context 'with block with two params' do
      let(:original_block) { ->(arg1, arg2) {} }

      it 'returns this block' do
        expect(block).to eq original_block
      end
    end

    context 'with block with one param' do
      let(:original_block) { ->(arg) { arg } }

      it 'returns block with two params that delegates first param to original block' do
        res = block

        expect(res).to be_a Proc
        expect(res.parameters.count).to eq 2
        expect(res.('foo', 'bar')).to eq 'foo'
      end
    end

    context 'without block and with delegate option' do
      before do
        allow(opts).to receive(:delegate?).and_return(true)
        allow(opts).to receive(:key).and_return(:size)
      end

      it 'constructs block that calls current key method on object' do
        res = block

        object = Array.new(3)
        expect(res).to be_a Proc
        expect(res.parameters.count).to eq 2
        expect(res.(object, nil)).to eq 3
      end
    end

    context 'without block and without delegate option' do
      let(:data) { { delegate: false } }
      let(:original_block) { nil }

      it 'returns nil' do
        expect(block).to eq nil
      end
    end
  end
end
