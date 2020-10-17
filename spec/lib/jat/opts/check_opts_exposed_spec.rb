# frozen_string_literal: true

RSpec.describe Jat::Opts::CheckOptsExposed do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { {} }

  it 'allows no exposed option' do
    expect { check.(params) }.not_to raise_error
  end

  it 'allows only boolean values in opts[:exposed]' do
    opts[:exposed] = false
    expect { check.(params) }.not_to raise_error

    opts[:exposed] = true
    expect { check.(params) }.not_to raise_error

    opts[:exposed] = nil
    expect { check.(params) }.to raise_error Jat::Error, /exposed/

    opts[:exposed] = :foo
    expect { check.(params) }.to raise_error Jat::Error, /exposed/
  end
end
