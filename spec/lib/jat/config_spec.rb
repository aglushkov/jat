# frozen_string_literal: true

RSpec.describe Jat::Config do
  let(:jat) { Class.new(Jat) }
  let(:config) { jat.config }

  describe '.new' do
    it 'initializes with default options' do
      expect(config.exposed).to eq :default
      expect(config.key_transform).to eq :none
      expect(config.meta).to eq({})
      expect(config.to_str).to be_a Proc
    end
  end

  describe '.inspect' do
    it 'returns name of jat class with ::Config suffix' do
      expect(config.class.inspect).to match(/#<Class:.*?>::Config/)
    end
  end

  describe '#opts_copy' do
    it 'deeply copies options' do
      config.auto_preload = false
      config.exposed = :none
      config.key_transform = :camelLower
      config.meta[:foo] = [1, 2, 3]

      copy = config.opts_copy
      expect(copy).to eq config.opts
      expect(copy).not_to equal config.opts
      expect(copy[:meta][:foo]).not_to equal config.opts[:meta][:foo]
    end
  end

  describe '#auto_preload=' do
    it 'changes auto_preload option' do
      config.auto_preload = false
      expect(config.auto_preload).to eq false
    end

    it 'raises error when invalid value provided' do
      expect { config.auto_preload = 1 }.to raise_error Jat::Error, /true, false/
    end
  end

  describe '#exposed=' do
    it 'changes exposed settings' do
      config.exposed = :none
      expect(config.exposed).to eq :none
    end

    it 'calls serializer #refresh' do
      allow(jat).to receive(:refresh)
      config.exposed = :none

      expect(jat).to have_received(:refresh)
    end

    it 'does not calls serializer #refresh when config not changed' do
      allow(jat).to receive(:refresh)
      config.exposed = :default

      expect(jat).not_to have_received(:refresh)
    end

    it 'raises error when invalid value provided' do
      expect { config.exposed = 1 }.to raise_error Jat::Error, /all.*none.*default/
    end
  end

  describe '#key_transform=' do
    it 'changes key_transform settings' do
      config.key_transform = :camelLower
      expect(config.key_transform).to eq :camelLower
    end

    it 'calls serializer #refresh' do
      allow(jat).to receive(:refresh)
      config.key_transform = :camelLower

      expect(jat).to have_received(:refresh)
    end

    it 'does not calls serializer #refresh when config not changed' do
      allow(jat).to receive(:refresh)
      config.key_transform = :none

      expect(jat).not_to have_received(:refresh)
    end

    it 'raises error when invalid value provided' do
      expect { config.key_transform = 1 }.to raise_error Jat::Error, /none.*camelLower/
    end
  end

  describe '#to_str=' do
    it 'changes to_str option' do
      new_to_str = -> {}
      config.to_str = new_to_str

      expect(config.to_str).to eq new_to_str
    end
  end
end
