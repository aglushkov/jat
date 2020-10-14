# frozen_string_literal: true

RSpec.describe Jat::Config do
  let(:jat) { Class.new(Jat) }

  let(:config) { described_class.new(jat) }

  it 'has default options' do
    config = described_class.new(jat)

    expect(config.delegate).to eq true
    expect(config.exposed).to eq :default
  end

  it 'allows to provide options when initialized' do
    config = described_class.new(jat, delegate: false, exposed: :none)

    expect(config.delegate).to eq false
    expect(config.exposed).to eq :none
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
      allow(jat).to receive(:refresh)
      expect { config.delegate = 1 }.to raise_error Jat::Error, /boolean/
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
      allow(jat).to receive(:refresh)
      expect { config.exposed = true }.to raise_error Jat::Error, /all.*none.*default/
    end
  end
end
