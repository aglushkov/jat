# frozen_string_literal: true

RSpec.describe Jat::AttributeParams::Checks::OptsMany do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { { serializer: nil } }

  it 'allows no `many` option' do
    expect { check.(params) }.not_to raise_error
  end

  it 'allows only boolean values in opts[:many]' do
    opts[:many] = false
    expect { check.(params) }.not_to raise_error

    opts[:many] = true
    expect { check.(params) }.not_to raise_error

    opts[:many] = nil
    expect { check.(params) }.to raise_error Jat::Error, /many/

    opts[:many] = :foo
    expect { check.(params) }.to raise_error Jat::Error, /many/
  end

  it 'does not allow to specify `many` option without serializer' do
    opts.delete(:serializer)
    opts[:many] = false

    expect { check.(params) }.to raise_error Jat::Error, /serializer/
  end
end
