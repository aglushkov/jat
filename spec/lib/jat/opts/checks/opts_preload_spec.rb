# frozen_string_literal: true

RSpec.describe Jat::Opts::Checks::OptsPreload do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { {} }

  it 'allows symbols, strings, hashes with symbol or string keys, arrays' do
    opts[:preload] = :a
    expect { check.(params) }.not_to raise_error

    opts[:preload] = 'a'
    expect { check.(params) }.not_to raise_error

    opts[:preload] = {}
    expect { check.(params) }.not_to raise_error

    opts[:preload] = []
    expect { check.(params) }.not_to raise_error

    opts[:preload] = nil
    expect { check.(params) }.not_to raise_error

    opts[:preload] = { a: :b }
    expect { check.(params) }.not_to raise_error

    opts[:preload] = { a: { b: :c } }
    expect { check.(params) }.not_to raise_error

    opts[:preload] = { a: { b: [{ c: :d }, :e] } }
    expect { check.(params) }.not_to raise_error

    opts[:preload] = [:a, { b: %i[c d] }]
    expect { check.(params) }.not_to raise_error

    opts[:preload] = ''
    expect { check.(params) }.to raise_error Jat::Error, /preload/

    opts[:preload] = :''
    expect { check.(params) }.to raise_error Jat::Error, /preload/

    opts[:preload] = { '' => :b }
    expect { check.(params) }.to raise_error Jat::Error, /preload/

    opts[:preload] = { '': :b }
    expect { check.(params) }.to raise_error Jat::Error, /preload/

    opts[:preload] = [1]
    expect { check.(params) }.to raise_error Jat::Error, /preload/

    opts[:preload] = { a: 1 }
    expect { check.(params) }.to raise_error Jat::Error, /preload/

    opts[:preload] = { 1 => :foo }
    expect { check.(params) }.to raise_error Jat::Error, /preload/
  end
end
