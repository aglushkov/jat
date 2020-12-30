# frozen_string_literal: true

RSpec.describe Jat::Opts::Checks::Opts do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: opts, block: nil } }
  let(:opts) { {} }

  it 'calls other validations' do
    allow(Jat::Opts::Checks::OptsKey).to receive(:call).with(params)
    allow(Jat::Opts::Checks::OptsExposed).to receive(:call).with(params)
    allow(Jat::Opts::Checks::OptsSerializer).to receive(:call).with(params)
    allow(Jat::Opts::Checks::OptsMany).to receive(:call).with(params)
    allow(Jat::Opts::Checks::OptsPreload).to receive(:call).with(params)

    check.(params)

    expect(Jat::Opts::Checks::OptsKey).to have_received(:call)
    expect(Jat::Opts::Checks::OptsExposed).to have_received(:call)
    expect(Jat::Opts::Checks::OptsSerializer).to have_received(:call)
    expect(Jat::Opts::Checks::OptsMany).to have_received(:call)
    expect(Jat::Opts::Checks::OptsPreload).to have_received(:call)
  end

  it 'does not allow user-provided keys' do
    opts[:foo] = 1
    opts[:bar] = false

    expect { check.(params) }.to raise_error(Jat::Error, /foo, bar/)
  end
end
