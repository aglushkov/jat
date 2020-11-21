# frozen_string_literal: true

RSpec.describe Jat::Config do
  let(:jat) { Class.new(Jat) }
  let(:config) { described_class.new(jat) }

  it 'has default options' do
    expect(config.delegate).to eq true
    expect(config.exposed).to eq :default
  end

  describe '#delegate=' do
    it 'changes delegate option' do
      config.delegate = false
      expect(config.delegate).to eq false
    end

    it 'calls serializer #refresh' do
      allow(jat).to receive(:refresh)
      config.delegate = false

      expect(jat).to have_received(:refresh)
    end

    it 'does not calls serializer #refresh when config not changed' do
      allow(jat).to receive(:refresh)
      config.delegate = true

      expect(jat).not_to have_received(:refresh)
    end

    it 'raises error when invalid value provided' do
      expect { config.delegate = 1 }.to raise_error Jat::Error, /true, false/
    end
  end

  describe '#exposed=' do
    it 'changes delegate option' do
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
    it 'changes delegate option' do
      config.key_transform = :camel_lower
      expect(config.key_transform).to eq :camel_lower
    end

    it 'calls serializer #refresh' do
      allow(jat).to receive(:refresh)
      config.key_transform = :camel_lower

      expect(jat).to have_received(:refresh)
    end

    it 'does not calls serializer #refresh when config not changed' do
      allow(jat).to receive(:refresh)
      config.key_transform = :none

      expect(jat).not_to have_received(:refresh)
    end

    it 'raises error when invalid value provided' do
      expect { config.key_transform = 1 }.to raise_error Jat::Error, /none.*camel_lower/
    end
  end

  describe '#to_str=' do
    it 'changes to_str option' do
      new_to_str = -> {}
      config.to_str = new_to_str

      expect(config.to_str).to eq new_to_str
    end
  end

  describe '#copy_to' do
    it 'copies options to another serializer' do
      config.delegate = false
      config.exposed = :all

      subclass = Class.new(jat)
      config.copy_to(subclass)

      expect(subclass.config.delegate).to eq false
      expect(subclass.config.exposed).to eq :all
    end
  end
end
