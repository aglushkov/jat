# frozen_string_literal: true

RSpec.describe Jat::Opts::CheckOpts do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { {} }

  it 'calls other validations' do
    allow(Jat::Opts::CheckOptsKey).to receive(:call).with(params)
    allow(Jat::Opts::CheckOptsDelegate).to receive(:call).with(params)
    allow(Jat::Opts::CheckOptsExposed).to receive(:call).with(params)
    allow(Jat::Opts::CheckOptsSerializer).to receive(:call).with(params)
    allow(Jat::Opts::CheckOptsMany).to receive(:call).with(params)
    allow(Jat::Opts::CheckOptsIncludes).to receive(:call).with(params)

    check.(params)

    expect(Jat::Opts::CheckOptsKey).to have_received(:call)
    expect(Jat::Opts::CheckOptsDelegate).to have_received(:call)
    expect(Jat::Opts::CheckOptsExposed).to have_received(:call)
    expect(Jat::Opts::CheckOptsSerializer).to have_received(:call)
    expect(Jat::Opts::CheckOptsMany).to have_received(:call)
    expect(Jat::Opts::CheckOptsIncludes).to have_received(:call)
  end

  it 'does not allow user-provided keys' do
    opts[:foo] = 1
    opts[:bar] = false

    expect { check.(params) }.to raise_error(Jat::Error, /foo, bar/)
  end
end
