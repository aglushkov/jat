# frozen_string_literal: true

RSpec.describe Jat::Opts::Checks::OptsIncludes do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { {} }

  it 'allows symbols, strings, hashes with symbol or string keys, arrays' do
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
