# frozen_string_literal: true

RSpec.describe Jat::Opts::CheckOptsIncludes do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { {} }

  it 'allows only one branch opts[:includes] when serializer provided' do
    opts[:serializer] = 'something'

    opts[:includes] = :a
    expect { check.(params) }.not_to raise_error

    opts[:includes] = 'a'
    expect { check.(params) }.not_to raise_error

    opts[:includes] = nil
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { foo: {} }
    expect { check.(params) }.not_to raise_error

    opts[:includes] = [:foo]
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { foo: :bar }
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { foo: { bar: :bazz } }
    expect { check.(params) }.not_to raise_error

    opts[:includes] = %i[foo bar]
    expect { check.(params) }.to raise_error Jat::Error, /includes/

    opts[:includes] = { foo: %i[bar bazz] }
    expect { check.(params) }.to raise_error Jat::Error, /includes/

    opts[:includes] = { foo: { bar1: :bazz1, bar2: :bazz2 } }
    expect { check.(params) }.to raise_error Jat::Error, /includes/
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

    opts[:includes] = nil
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { a: :b }
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { a: { b: :c } }
    expect { check.(params) }.not_to raise_error

    opts[:includes] = { a: { b: [{ c: :d }, :e] } }
    expect { check.(params) }.not_to raise_error

    opts[:includes] = [:a, { b: %i[c d] }]
    expect { check.(params) }.not_to raise_error

    opts[:includes] = ''
    expect { check.(params) }.to raise_error Jat::Error, /includes/

    opts[:includes] = :''
    expect { check.(params) }.to raise_error Jat::Error, /includes/

    opts[:includes] = { '' => :b }
    expect { check.(params) }.to raise_error Jat::Error, /includes/

    opts[:includes] = { '': :b }
    expect { check.(params) }.to raise_error Jat::Error, /includes/

    opts[:includes] = [1]
    expect { check.(params) }.to raise_error Jat::Error, /includes/

    opts[:includes] = { a: 1 }
    expect { check.(params) }.to raise_error Jat::Error, /includes/

    opts[:includes] = { 1 => :foo }
    expect { check.(params) }.to raise_error Jat::Error, /includes/
  end
end
