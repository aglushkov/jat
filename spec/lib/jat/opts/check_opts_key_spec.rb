# frozen_string_literal: true

RSpec.describe Jat::Opts::CheckOptsKey do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { {} }

  it 'allows no key option' do
    expect { check.(params) }.not_to raise_error
  end

  it 'allows only symbol or string as opts[:key]' do
    opts[:key] = :name
    expect { check.(params) }.not_to raise_error

    opts[:key] = 'name'
    expect { check.(params) }.not_to raise_error

    opts[:key] = nil
    expect { check.(params) }.to raise_error Jat::Error, /key/

    opts[:key] = {}
    expect { check.(params) }.to raise_error Jat::Error, /key/
  end

  it 'does not allow opts :key and block together' do
    params[:block] = 'something'

    opts[:key] = :foo
    expect { check.(params) }.to raise_error Jat::Error, /key.*block/
  end
end
