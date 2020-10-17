# frozen_string_literal: true

RSpec.describe Jat::Opts::CheckName do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: {}, block: nil } }

  it 'calls other validations' do
    allow(Jat::Opts::CheckNameFormat).to receive(:call).with(params)
    allow(Jat::Opts::CheckNameReserved).to receive(:call).with(params)

    check.(params)

    expect(Jat::Opts::CheckNameFormat).to have_received(:call)
    expect(Jat::Opts::CheckNameReserved).to have_received(:call)
  end
end
