# frozen_string_literal: true

RSpec.describe Jat::Opts::Validate do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: {}, block: nil } }

  it 'calls other validations' do
    allow(Jat::Opts::Checks::Name).to receive(:call).with(params)
    allow(Jat::Opts::Checks::Opts).to receive(:call).with(params)
    allow(Jat::Opts::Checks::Block).to receive(:call).with(params)

    check.(params)

    expect(Jat::Opts::Checks::Name).to have_received(:call)
    expect(Jat::Opts::Checks::Opts).to have_received(:call)
    expect(Jat::Opts::Checks::Block).to have_received(:call)
  end
end
