# frozen_string_literal: true

RSpec.describe Jat::CheckKey do
  let(:check) { described_class }
  let(:params) { { name: name, opts: opts, block: nil } }
  let(:name) { :name }
  let(:opts) { {} }

  it 'allows only symbol or string as name' do
    params[:name] = :name
    expect { check.(params) }.not_to raise_error

    params[:name] = 'name'
    expect { check.(params) }.not_to raise_error

    params[:name] = nil
    expect { check.(params) }.to raise_error Jat::Error, /name/

    params[:name] = {}
    expect { check.(params) }.to raise_error Jat::Error, /name/
  end

  it 'does not allows to add attribute and relationship with `type` and `id` names' do
    params[:name] = :id
    expect { check.(params) }.to raise_error Jat::Error, /Attribute can't have `id` name/

    params[:name] = :type
    expect { check.(params) }.to raise_error Jat::Error, /Attribute can't have `type` name/

    params[:opts][:serializer] = Class.new(Jat)

    params[:name] = :id
    expect { check.(params) }.to raise_error Jat::Error, /Relationship can't have `id` name/

    params[:name] = :type
    expect { check.(params) }.to raise_error Jat::Error, /Relationship can't have `type` name/
  end

  it 'allows only 1 or 2 arguments in block' do
    params[:block] = ->(a) {}
    expect { check.(params) }.not_to raise_error

    params[:block] = ->(a, b) {}
    expect { check.(params) }.not_to raise_error

    params[:block] = ->(a = 1, b = 2) {}
    expect { check.(params) }.not_to raise_error

    params[:block] = ->(a, b, c) {}
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = ->(a, b:) {}
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = ->(a, *b) {}
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = proc { |a| }
    expect { check.(params) }.not_to raise_error

    params[:block] = proc { |a, b| }
    expect { check.(params) }.not_to raise_error

    params[:block] = proc { |a = 1, b = 2| }
    expect { check.(params) }.not_to raise_error

    params[:block] = proc { |a, b, c| }
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = proc { |a, b:| }
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = proc { |a, *b| }
    expect { check.(params) }.to raise_error Jat::Error, /block/i
  end

  it 'allows only symbol or string as opts[:key]' do
    opts[:key] = :name
    expect { check.(params) }.not_to raise_error

    opts[:key] = 'name'
    expect { check.(params) }.not_to raise_error

    opts[:key] = nil
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:key\]/

    opts[:key] = {}
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:key\]/
  end

  it 'allows only boolean values in opts[:delegate]' do
    opts[:delegate] = false
    expect { check.(params) }.not_to raise_error

    opts[:delegate] = true
    expect { check.(params) }.not_to raise_error

    opts[:delegate] = nil
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:delegate\]/

    opts[:delegate] = :foo
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:delegate\]/
  end

  it 'allows only subclass of Jat serializer class in opts[:serializer]' do
    opts[:many] = true
    opts[:serializer] = Class.new(Jat)
    expect { check.(params) }.not_to raise_error

    opts[:serializer] = nil
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:serializer\]/

    opts[:serializer] = []
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:serializer\]/

    opts[:serializer] = Class.new
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:serializer\]/

    opts[:serializer] = [Class.new]
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:serializer\]/
  end

  it 'does not allows opts :key and block together' do
    params[:block] = ->(a, b) {}

    # allows only when key is same as name
    opts[:key] = name
    expect { check.(params) }.not_to raise_error

    opts[:key] = :foobar
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:key\].*block/
  end

  it 'allows only string or symbol opts[:includes] when serializer provided' do
    opts.merge!(serializer: Class.new(Jat), many: false)

    opts[:includes] = :a
    expect { check.(params) }.not_to raise_error

    opts[:includes] = 'a'
    expect { check.(params) }.not_to raise_error

    opts[:includes] = nil
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { foo: :bar }
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:includes\]/

    opts[:includes] = [:foo]
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:includes\]/
  end

  it 'allows simple objects in opts[:includes] (symbol, string, hash with symbol or string keys, array)' do
    opts[:includes] = :a
    expect { check.(params) }.not_to raise_error

    opts[:includes] = 'a'
    expect { check.(params) }.not_to raise_error

    opts[:includes] = {}
    expect { check.(params) }.not_to raise_error

    opts[:includes] = []
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { a: :b }
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { a: { b: :c } }
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { a: { b: [{ c: :d }, :e] } }
    expect { check.(params) }.not_to raise_error

    opts[:includes] = [:a, b: [:c, :d]]
    expect { check.(params) }.not_to raise_error

    opts[:includes] = nil
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:includes\]/

    opts[:includes] = [1]
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:includes\]/

    opts[:includes] = { a: 1 }
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:includes\]/

    opts[:includes] = { 1 => :foo }
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:includes\]/
  end

  it 'required opts[:many] of type Boolean when serializer provided' do
    opts[:serializer] = Class.new(Jat)
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:many\].*opts\[:serializer\]/

    opts[:many] = nil
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:many\].*boolean/i

    opts[:many] = :foo
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:many\].*boolean/i

    opts[:many] = true
    expect { check.(params) }.not_to raise_error

    opts[:many] = false
    expect { check.(params) }.not_to raise_error
  end

  it 'required opts[:many] to be not provided when serializer not provided' do
    opts[:many] = true
    expect { check.(params) }.to raise_error Jat::Error, /opts\[:many\].*opts\[:serializer\]/
  end

  it 'checks extra opts keys' do
    opts[:foo] = true
    expect { check.(params) }.to raise_error Jat::Error, /foo/
  end
end
