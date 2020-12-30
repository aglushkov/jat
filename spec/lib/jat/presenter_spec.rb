# frozen_string_literal: true

RSpec.describe Jat::Presenter do
  let(:presenter_class) do
    Class.new(Jat)::Presenter
  end

  let(:presenter) { presenter_class.new('OBJECT', 'CONTEXT') }

  describe '#new' do
    it 'initializes with public attributes object and context' do
      expect(presenter.object).to eq 'OBJECT'
      expect(presenter.context).to eq 'CONTEXT'
    end
  end

  describe '.inspect' do
    it 'returns name of jat class with ::Presenter suffix' do
      expect(presenter_class.inspect).to match(/#<Class:.*?>::Presenter/)
    end
  end

  describe '.add_method' do
    it 'adds method by providing block without variables' do
      presenter_class.add_method(:foo, proc { [object, context] })
      expect(presenter.foo).to eq %w[OBJECT CONTEXT]
    end

    it 'adds method by providing block with one variables' do
      presenter_class.add_method(:foo, proc { |obj| [obj, object, context] })
      expect(presenter.foo).to eq %w[OBJECT OBJECT CONTEXT]
    end

    it 'adds method by providing block with two variables' do
      presenter_class.add_method(:foo, proc { |obj, ctx| [obj, ctx, object, context] })
      expect(presenter.foo).to eq %w[OBJECT CONTEXT OBJECT CONTEXT]
    end

    it 'raises error when block has more than two variables' do
      expect { presenter_class.add_method(:foo, proc { |_a, _b, _c| nil }) }.to raise_error(/count/)
    end
  end
end
