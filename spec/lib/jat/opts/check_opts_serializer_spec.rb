# frozen_string_literal: true

RSpec.describe Jat::Opts::CheckOptsSerializer do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { {} }

  it 'allows no `serializer` option' do
    expect { check.(params) }.not_to raise_error
  end

  it 'allows only direct Jat subclass or callable in opts[:serializer]' do
    opts[:serializer] = Class.new(Jat)
    expect { check.(params) }.not_to raise_error

    opts[:serializer] = -> { Class.new(Jat) }
    expect { check.(params) }.not_to raise_error

    opts[:serializer] = ->(_foo) { Class.new(Jat) }
    expect { check.(params) }.to raise_error Jat::Error, /no params/

    opts[:serializer] = nil
    expect { check.(params) }.to raise_error Jat::Error, /Jat.*proc/
  end
end
