# frozen_string_literal: true

RSpec.describe Jat::CheckAttribute do
  let(:check) { described_class }
  let(:params) { { name: name, opts: opts, block: nil } }
  let(:name) { :name }
  let(:opts) { {} }

  it 'allows only symbol or string as name' do
    params[:name] = :name
    expect { check.new(*params.values).validate }.not_to raise_error

    params[:name] = 'name'
    expect { check.new(*params.values).validate }.not_to raise_error

    params[:name] = nil
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /name/

    params[:name] = {}
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /name/
  end

  it 'does not allows to add attribute and relationship with `type` and `id` names' do
    params[:name] = :id
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /Attribute can't have `id` name/

    params[:name] = :type
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /Attribute can't have `type` name/

    params[:opts][:serializer] = Class.new(Jat)

    params[:name] = :id
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /Relationship can't have `id` name/

    params[:name] = :type
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /Relationship can't have `type` name/
  end

  it 'does not allow to add names starting or ending with - or _' do
    params[:name] = '-foo'
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = 'foo-'
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = '_foo'
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = 'foo_'
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = '_'
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = '-'
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /'-' or '_'/
  end

  it 'allows name with a-z, A-Z, 0-9, `-` and `_`' do
    part1 = ('a'..'z').to_a.join
    part2 = ('A'..'Z').to_a.join
    part3 = (0..9).to_a.join
    params[:name] = "#{part1}-#{part2}_#{part3}"
    expect { check.new(*params.values).validate }.not_to raise_error
  end

  it 'prohibits name with non a-z, A-Z, 0-9, `-` and `_` symbols' do
    params[:name] = 'abc!'
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /A-Z/
  end

  it 'allows only 1 or 2 arguments in block' do
    params[:block] = ->(a) {}
    expect { check.new(*params.values).validate }.not_to raise_error

    params[:block] = ->(a, b) {}
    expect { check.new(*params.values).validate }.not_to raise_error

    params[:block] = ->(a = 1, b = 2) {}
    expect { check.new(*params.values).validate }.not_to raise_error

    params[:block] = ->(a, b, c) {}
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /block/i

    params[:block] = ->(a, b:) {}
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /block/i

    params[:block] = ->(a, *b) {}
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /block/i

    params[:block] = proc { |a| }
    expect { check.new(*params.values).validate }.not_to raise_error

    params[:block] = proc { |a, b| }
    expect { check.new(*params.values).validate }.not_to raise_error

    params[:block] = proc { |a = 1, b = 2| }
    expect { check.new(*params.values).validate }.not_to raise_error

    params[:block] = proc { |a, b, c| }
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /block/i

    params[:block] = proc { |a, b:| }
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /block/i

    params[:block] = proc { |a, *b| }
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /block/i
  end

  it 'allows only symbol or string as opts[:key]' do
    opts[:key] = :name
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:key] = 'name'
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:key] = nil
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:key\]/

    opts[:key] = {}
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:key\]/
  end

  it 'allows only boolean values in opts[:delegate]' do
    opts[:delegate] = false
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:delegate] = true
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:delegate] = nil
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:delegate\]/

    opts[:delegate] = :foo
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:delegate\]/
  end

  it 'allows only direct serializer or callable in opts[:serializer]' do
    opts[:many] = true
    opts[:serializer] = Class.new(Jat)
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:serializer] = -> { Class.new(Jat) }
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:serializer] = ->(_foo) { Class.new(Jat) }
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /no params/

    opts[:serializer] = nil
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /callable/
  end

  it 'requires opts[:serializer] with opts[:many]' do
    opts[:many] = true
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:many\].*opts\[:serializer\]/

    opts[:serializer] = Class.new(Jat)
    expect { check.new(*params.values).validate }.not_to raise_error
  end

  it 'does not allows opts :key and block together' do
    params[:block] = ->(a, b) {}

    # allows only when key is same as name
    opts[:key] = name
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:key] = :foobar
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:key\].*block/
  end

  it 'allows only string or symbol opts[:includes] when serializer provided' do
    opts.merge!(serializer: Class.new(Jat), many: false)

    opts[:includes] = :a
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = 'a'
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = nil
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = { foo: :bar }
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:includes\]/

    opts[:includes] = [:foo]
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:includes\]/
  end

  it 'allows simple objects in opts[:includes] (symbol, string, hash with symbol or string keys, array)' do
    opts[:includes] = :a
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = 'a'
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = {}
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = []
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = nil
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = { a: :b }
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = { a: { b: :c } }
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = { a: { b: [{ c: :d }, :e] } }
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = [:a, { b: %i[c d] }]
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:includes] = [1]
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:includes\]/

    opts[:includes] = { a: 1 }
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:includes\]/

    opts[:includes] = { 1 => :foo }
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:includes\]/
  end

  it 'required opts[:many] of type Boolean if provided' do
    opts[:serializer] = Class.new(Jat)

    opts.delete(:many)
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:many] = true
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:many] = false
    expect { check.new(*params.values).validate }.not_to raise_error

    opts[:many] = nil
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:many\].*boolean/i

    opts[:many] = :foo
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /opts\[:many\].*boolean/i
  end

  it 'checks extra opts keys' do
    opts[:foo] = true
    expect { check.new(*params.values).validate }.to raise_error Jat::Error, /foo/
  end
end
