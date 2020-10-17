# frozen_string_literal: true

RSpec.describe Jat::Opts::Check do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: {}, block: nil } }

  it 'calls other validations' do
    allow(Jat::Opts::CheckName).to receive(:call).with(params)
    allow(Jat::Opts::CheckOpts).to receive(:call).with(params)
    allow(Jat::Opts::CheckBlock).to receive(:call).with(params)

    check.(params)

    expect(Jat::Opts::CheckName).to have_received(:call)
    expect(Jat::Opts::CheckOpts).to have_received(:call)
    expect(Jat::Opts::CheckBlock).to have_received(:call)
  end
end
