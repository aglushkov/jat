# frozen_string_literal: true

require 'jat/plugins/json_api'

RSpec.describe Jat::Plugins::JSON_API::Serializer do
  it 'returns empty hash when nothing to serialize' do
    empty_serializer = Class.new(Jat) { type(:type)  }
    result = described_class.(nil, empty_serializer)

    expect(result).to eq({})
  end

  it 'returns json-api structure with meta' do
    empty_serializer = Class.new(Jat) { type(:type)  }
    result = described_class.(nil, empty_serializer, meta: { any: :thing })

    expect(result).to eq(meta: { any: :thing })
  end

  it 'returns json-api structure with data' do
    str_serializer = Class.new(Jat) do
      type 'str'
      id { |_| 'STRING' }
    end

    result = described_class.('STRING', str_serializer)
    expect(result).to eq(data: { type: :str, id: 'STRING' })
  end

  it 'returns json-api structure with array data' do
    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj }
    end

    result = described_class.(%w[1 2], str_serializer, many: true)
    expect(result).to eq(data: [{ type: :str, id: '1' }, { type: :str, id: '2' }])
  end

  it 'returns json-api structure with data and meta' do
    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj }
    end

    result = described_class.('STRING', str_serializer, meta: { any: :thing })
    expect(result).to eq(data: { type: :str, id: 'STRING' }, meta: { any: :thing })
  end

  it 'returns json-api structure with data with attributes' do
    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj[0] }
      attribute :length

      def length(obj); obj.length; end
    end

    result = described_class.('STRING', str_serializer)
    expect(result).to eq(data: { type: :str, id: 'S', attributes: { length: 6 } })
  end

  it 'returns json-api structure with has-one relationship' do
    int_serializer = Class.new(Jat) do
      type 'int'
      id { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj[0] }
      def length(obj); obj.length; end

      relationship :length, serializer: int_serializer, exposed: true
    end

    result = described_class.('STRING', str_serializer)

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
      id { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj[0] }
      def length(obj); obj.length; end

      relationship :length, serializer: int_serializer
    end

    result = described_class.('STRING', str_serializer)

    expect(result).to eq(data: { type: :str, id: 'S' })
  end

  it 'returns json-api structure with empty has-one relationship' do
    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj[0] }
      def length(obj); nil; end

      relationship :length, serializer: self, exposed: true
    end

    result = described_class.('STRING', str_serializer)

    expect(result).to eq(
      data: {
        type: :str, id: 'S',
        relationships: { length: { data: nil } }
      }
    )
  end

  it 'returns json-api structure with has-one relationship with attributes' do
    int_serializer = Class.new(Jat) do
      type 'int'
      id { |obj| obj }
      def next(obj); obj + 1; end

      attribute :next
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj[0] }
      def length(obj); obj.length; end

      relationship :length, serializer: int_serializer, exposed: true
    end

    result = described_class.('STRING', str_serializer)

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

  it 'returns json-api structure with has-many relationship' do
    chr_serializer = Class.new(Jat) do
      type 'chr'
      id { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj[0] }
      def chars(obj); obj.chars; end

      relationship :chars, serializer: chr_serializer, many: true, exposed: true
    end

    result = described_class.('ab', str_serializer)

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

  it 'returns json-api structure with has-many relationship with attributes' do
    chr_serializer = Class.new(Jat) do
      type 'chr'
      id { |obj| obj }
      def next(obj); obj.next; end

      attribute :next
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj[0] }
      def chars(obj); obj.chars; end

      relationship :chars, serializer: chr_serializer, many: true, exposed: true
    end

    result = described_class.('ab', str_serializer)

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
      id { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj[0] }
      def chars(obj); obj.chars; end

      relationship :chars, serializer: chr_serializer, many: true, exposed: false
    end

    result = described_class.('ab', str_serializer, params: { include: 'chars' })

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
      id { |obj| obj }
    end

    str_serializer = Class.new(Jat) do
      type 'str'
      id { |obj| obj[0] }
      def chars(obj); obj.chars; end

      relationship :chars, serializer: chr_serializer, many: true, exposed: false
    end

    result = described_class.('ab', str_serializer, params: { fields: { str: 'chars' } })

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
end
