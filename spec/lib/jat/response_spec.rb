# frozen_string_literal: true

RSpec.describe Jat::Response do
  let(:response_class) { Class.new(Jat)::Response }

  before { Jat.config.auto_preload = false }

  after { Jat.config.auto_preload = true }

  describe '.inspect' do
    it 'returns name of jat class with ::Response suffix' do
      expect(response_class.inspect).to match(/#<Class:.*?>::Response/)
    end
  end

  it 'returns empty hash when nothing to serialize' do
    empty_serializer = Class.new(Jat) { type(:type) }
    result = empty_serializer.new.to_h(nil)

    expect(result).to eq({})
  end

  it 'returns correct structure with meta' do
    empty_serializer = Class.new(Jat) { type(:type) }
    result = empty_serializer.new.to_h(nil, meta: { any: :thing })

    expect(result).to eq(meta: { any: :thing })
  end

  it 'returns correct structure with data' do
    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |_| 'STRING' }
    end

    result = str_serializer.new.to_h('STRING')
    expect(result).to eq(data: { type: :str, id: 'STRING' })
  end

  it 'returns correct structure with array data' do
    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj }
    end

    result = str_serializer.new.to_h(%w[1 2], many: true)
    expect(result).to eq(data: [{ type: :str, id: '1' }, { type: :str, id: '2' }])
  end

  it 'returns correct structure with data and meta' do
    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj }
    end

    result = str_serializer.new.to_h('STRING', meta: { any: :thing })
    expect(result).to eq(data: { type: :str, id: 'STRING' }, meta: { any: :thing })
  end

  it 'returns correct structure with data with attributes' do
    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj[0] }
      attribute :length
    end

    result = str_serializer.new.to_h('STRING')
    expect(result).to eq(data: { type: :str, id: 'S', attributes: { length: 6 } })
  end

  it 'returns correct structure with has-one relationship' do
    int_serializer = Class.new(Jat) do
      type 'int'
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj[0] }
      relationship :length, serializer: int_serializer, exposed: true
    end

    result = str_serializer.new.to_h('STRING')

    expect(result).to eq(
      data: {
        type: :str, id: 'S',
        relationships: {
          length: { data: { type: :int, id: 6 } }
        }
      },
      included: [
        { type: :int, id: 6 }
      ]
    )
  end

  it 'does not return has-one relationship when not exposed' do
    int_serializer = Class.new(Jat) do
      type 'int'
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj[0] }
      relationship :length, serializer: int_serializer
    end

    result = str_serializer.new.to_h('STRING')

    expect(result).to eq(data: { type: :str, id: 'S' })
  end

  it 'returns correct structure with empty has-one relationship' do
    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj[0] }
      relationship(:length, serializer: self, exposed: true) { |_obj| nil }
    end

    result = str_serializer.new.to_h('STRING')

    expect(result).to eq(
      data: {
        type: :str, id: 'S',
        relationships: { length: { data: nil } }
      }
    )
  end

  it 'returns correct structure with has-one relationship with attributes' do
    int_serializer = Class.new(Jat) do
      type 'int'
      attribute(:id) { |obj| obj }
      attribute(:next) { |obj| obj + 1 }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj[0] }
      relationship :length, serializer: int_serializer, exposed: true
    end

    result = str_serializer.new.to_h('STRING')

    expect(result).to eq(
      data: {
        type: :str, id: 'S',
        relationships: {
          length: { data: { type: :int, id: 6 } }
        }
      },
      included: [
        { type: :int, id: 6, attributes: { next: 7 } }
      ]
    )
  end

  it 'returns correct structure with empty has-many relationship' do
    chr_serializer = Class.new(Jat) do
      type 'chr'
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |_obj| 'id' }
      relationship :chars, serializer: chr_serializer, many: true, exposed: true
    end

    result = str_serializer.new.to_h('')
    expect(result).to eq(
      data: {
        type: :str, id: 'id',
        relationships: { chars: { data: [] } }
      }
    )
  end

  it 'returns correct structure with has-many relationship' do
    chr_serializer = Class.new(Jat) do
      type 'chr'
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj[0] }
      relationship :chars, serializer: chr_serializer, many: true, exposed: true
    end

    result = str_serializer.new.to_h('ab')

    expect(result).to eq(
      data: {
        type: :str, id: 'a',
        relationships: {
          chars: { data: [{ type: :chr, id: 'a' }, { type: :chr, id: 'b' }] }
        }
      },
      included: [
        { type: :chr, id: 'a' }, { type: :chr, id: 'b' }
      ]
    )
  end

  it 'returns correct structure with has-many relationship with attributes' do
    chr_serializer = Class.new(Jat) do
      type 'chr'
      attribute(:id) { |obj| obj }
      attribute :next
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj[0] }
      relationship :chars, serializer: chr_serializer, many: true, exposed: true
    end

    result = str_serializer.new.to_h('ab')

    expect(result).to eq(
      data: {
        type: :str, id: 'a',
        relationships: {
          chars: { data: [{ type: :chr, id: 'a' }, { type: :chr, id: 'b' }] }
        }
      },
      included: [
        { type: :chr, id: 'a', attributes: { next: 'b' } },
        { type: :chr, id: 'b', attributes: { next: 'c' } }
      ]
    )
  end

  it 'accepts includes param' do
    chr_serializer = Class.new(Jat) do
      type 'chr'
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj[0] }
      relationship :chars, serializer: chr_serializer, many: true, exposed: false
    end

    result = str_serializer.new(params: { include: 'chars' }).to_h('ab')

    expect(result).to eq(
      data: {
        type: :str, id: 'a',
        relationships: {
          chars: { data: [{ type: :chr, id: 'a' }, { type: :chr, id: 'b' }] }
        }
      },
      included: [
        { type: :chr, id: 'a' }, { type: :chr, id: 'b' }
      ]
    )
  end

  it 'accepts sparse_fieldset' do
    chr_serializer = Class.new(Jat) do
      type 'chr'
      attribute(:id) { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      attribute(:id) { |obj| obj[0] }
      relationship :chars, serializer: chr_serializer, many: true, exposed: false
    end

    result = str_serializer.new(params: { fields: { str: 'chars' } }).to_h('ab')

    expect(result).to eq(
      data: {
        type: :str, id: 'a',
        relationships: {
          chars: { data: [{ type: :chr, id: 'a' }, { type: :chr, id: 'b' }] }
        }
      },
      included: [
        { type: :chr, id: 'a' }, { type: :chr, id: 'b' }
      ]
    )
  end

  describe 'meta' do
    it 'adds static and dynamic meta defined in serializer config' do
      serializer = Class.new(Jat) do
        type :foo
        attribute(:id) { |obj| obj }

        config.meta = { version: '1.2.3' }
        # config.meta[:version] = '1.2.3'
        config.meta[:uid] = ->(obj, context) { [obj, context[:time]] }
      end

      result = serializer.to_h('bar', time: '12:00')

      expect(result).to eq(
        data: { type: :foo, id: 'bar' },
        meta: {
          version: '1.2.3',
          uid: ['bar', '12:00']
        }
      )
    end

    it 'does not overwrites manually added meta' do
      serializer = Class.new(Jat) do
        type :foo
        attribute(:id) { |obj| obj }

        config.meta[:version] = '1.2.3'
      end

      result = serializer.to_h('bar', meta: { version: '1.2.4' })

      expect(result).to eq(
        data: { type: :foo, id: 'bar' },
        meta: { version: '1.2.4' }
      )
    end

    it 'does not add meta with nil values' do
      serializer = Class.new(Jat) do
        type :foo
        attribute(:id, key: :itself)
        config.meta[:foo] = nil
        config.meta[:bar] = proc {}
        config.meta[:bazz] = proc { false }
        config.meta[:bazzz] = false
      end

      result = serializer.to_h('bar')
      expect(result).to eq(data: { type: :foo, id: 'bar' }, meta: { bazz: false, bazzz: false })
    end
  end
end
