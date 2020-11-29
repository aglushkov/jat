# frozen_string_literal: true

RSpec.describe Jat::Opts::Checks::OptsDelegate do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { {} }

  it 'allows no delegate option' do
    expect { check.(params) }.not_to raise_error
  end

  it 'allows only boolean values in opts[:delegate]' do
    opts[:delegate] = false
    expect { check.(params) }.not_to raise_error

    opts[:delegate] = true
    expect { check.(params) }.not_to raise_error

    opts[:delegate] = nil
    expect { check.(params) }.to raise_error Jat::Error, /delegate/

    opts[:delegate] = :foo
    expect { check.(params) }.to raise_error Jat::Error, /delegate/
  end
end
