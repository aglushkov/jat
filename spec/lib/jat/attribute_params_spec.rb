# frozen_string_literal: true

RSpec.describe Jat::AttributeParams do
  let(:jat) { Class.new(Jat) }

  let(:opts) { described_class.new(jat, params) }
  let(:params) { { name: :name, opts: {}, block: nil } }

  describe '#name' do
    subject(:new_name) { opts.name }

    it 'symbolizes name' do
      params[:name] = 'foo_bar'
      expect(new_name).to eq :foo_bar
    end

    it 'make lowerCamelCase with config key_transform=camelLower' do
      jat.config.key_transform = :camelLower
      params[:name] = 'foo_bar_bazz'
      expect(new_name).to eq :fooBarBazz
    end
  end

  describe '#key' do
    subject(:key) { opts.key }

    context 'when no key provided' do
      it 'defaults to name' do
        params[:name] = 'foo'
        expect(key).to eq :foo
      end

      it 'defaults to original name with config key_transform=camelLower' do
        jat.config.key_transform = :camelLower
        params[:name] = 'foo_bar'
        expect(key).to eq :foo_bar
      end
    end

    context 'when key provided' do
      it 'returns symbolized data key' do
        params[:opts] = { key: 'foo_key' }
        expect(key).to eq :foo_key
      end
    end
  end

  describe '#exposed?' do
    subject(:is_exposed) { opts.exposed? }

    context 'when key provided' do
      it 'returns provided value' do
        params[:opts] = { exposed: false }
        expect(is_exposed).to eq false
      end
    end

    context 'when all keys are exposed' do
      before { jat.config.exposed = :all }

      it 'returns true' do
        expect(is_exposed).to eq true
      end
    end

    context 'when no keys are exposed' do
      before { jat.config.exposed = :none }

      it 'returns false' do
        expect(is_exposed).to eq false
      end
    end

    context 'with serializer by default' do
      before { jat.config.exposed = :default }

      it 'returns false when has serializer' do
        params[:opts] = { serializer: jat }
        expect(is_exposed).to eq false
      end
    end

    context 'without serializer by default' do
      before { jat.config.exposed = :default }

      it 'returns true' do
        params[:opts] = {}
        expect(is_exposed).to eq true
      end
    end
  end

  describe '#many?' do
    subject(:is_many) { opts.many? }

    context 'when no key provided' do
      it 'returns nil' do
        expect(is_many).to eq nil
      end
    end

    context 'when key provided' do
      it 'returns provided data' do
        params[:opts] = { many: true, serializer: Class.new(Jat) }
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
      it 'returns true' do
        params[:opts] = { serializer: jat }
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
      it 'returns provided serializer' do
        params[:opts] = { serializer: jat }
        expect(serializer).to eq jat
      end
    end

    context 'with serializer key as callable' do
      it 'returns Proc' do
        params[:opts] = { serializer: -> { jat } }
        expect(serializer).to be_a Proc
        expect(serializer.()).to eq jat
      end
    end

    context 'when callable serializer returns not a Jat serializer class' do
      it 'raises error' do
        params[:opts] = { serializer: -> { nil } }
        expect(serializer).to be_a Proc
        expect { serializer.() }.to raise_error Jat::Error, /must be a subclass of Jat/
      end
    end
  end

  describe '#preloads_with_path' do
    subject(:preloads_with_path) { opts.preloads_with_path }

    before { jat.config.auto_preload = true }

    context 'when no data provided and no serializer' do
      it 'returns empty hash as preloads and nil as path' do
        expect(preloads_with_path).to eq [{}, nil]
      end
    end

    context 'when data provided without serializer' do
      it 'returns transformed hash' do
        params[:opts] = { preload: { some: :data } }
        expect(preloads_with_path).to eq [{ some: { data: {} } }, nil]
      end
    end

    context 'when no data provided and serializer exists' do
      it 'generates hash from current key' do
        params[:opts] = { serializer: jat }
        allow(opts).to receive(:key).and_return(:foobar)

        expect(preloads_with_path).to eq [{ foobar: {} }, [:foobar]]
      end
    end

    context 'when data provided and serializer exists' do
      it 'returns transformed hash' do
        params[:opts] = { serializer: jat, preload: :data }
        expect(preloads_with_path).to eq [{ data: {} }, [:data]]
      end
    end

    context 'when specified main preloaded resource (via "!")' do
      it 'returns transformed hash' do
        params[:opts] = { serializer: jat, preload: { a: { b!: { c: {} }, d: {} }, e: {} } }
        expect(preloads_with_path).to eq [
          { a: { b: { c: {} }, d: {} }, e: {} },
          %i[a b]
        ]
      end
    end

    context 'when data is nil and no serializer' do
      [nil, false].each do |data|
        it 'returns [nil, nil]' do
          params[:opts] = { preload: data }
          expect(preloads_with_path).to eq [nil, nil]
        end
      end
    end

    context 'when data is falsey and serializer exists' do
      [nil, false].each do |data|
        it 'returns [nil, nil]' do
          params[:opts] = { preload: data, serializer: jat }
          expect(preloads_with_path).to eq [nil, nil]
        end
      end
    end

    context 'when data is empty and serializer exists' do
      it 'returns empty hash as preloads and nil as path' do
        [[], {}].each do |preloads|
          params[:opts] = { preload: preloads, serializer: jat }
          expect(preloads_with_path).to eq [{}, nil]
        end
      end
    end

    context 'when config auto_preload is false' do
      before { jat.config.auto_preload = false }

      it 'returns [nil, nil]' do
        params[:opts] = { serializer: jat, preload: { a: { b!: { c: {} } } } }
        expect(preloads_with_path).to eq [nil, nil]
      end
    end
  end

  describe '#block' do
    subject(:block) { opts.block }

    context 'with block with no params' do
      it 'returns this block' do
        params[:block] = -> {}
        expect(block).to eq params[:block]
      end
    end

    context 'with block with one param' do
      it 'returns this block' do
        params[:block] = ->(arg1) {}
        expect(block).to eq params[:block]
      end
    end

    context 'with block with two params' do
      it 'returns this block' do
        params[:block] = ->(arg1, arg2) {}
        expect(block).to eq params[:block]
      end
    end

    context 'without block and with key option' do
      before do
        allow(opts).to receive(:key).and_return(:size)
      end

      it 'constructs block that calls current key method on object' do
        res = block

        object = Array.new(3)
        expect(res).to be_a Proc
        expect(res.parameters.count).to eq 0

        presenter = jat::Presenter.new(object, {})
        expect(presenter.instance_exec(&block)).to eq 3
      end
    end

    context 'without block and without key option' do
      before do
        params[:name] = :size
        params[:block] = nil
      end

      it 'constructs block that calls current option name method on object' do
        res = block

        object = Array.new(3)
        expect(res).to be_a Proc
        expect(res.parameters.count).to eq 0

        presenter = jat::Presenter.new(object, {})
        expect(presenter.instance_exec(&block)).to eq 3
      end
    end
  end
end
