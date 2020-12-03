# frozen_string_literal: true

RSpec.describe Jat::Opts::Checks::Name do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: {}, block: nil } }

  it 'calls other validations' do
    allow(Jat::Opts::Checks::NameFormat).to receive(:call).with(params)
    allow(Jat::Opts::Checks::NameReserved).to receive(:call).with(params)

    check.(params)

    expect(Jat::Opts::Checks::NameFormat).to have_received(:call)
    expect(Jat::Opts::Checks::NameReserved).to have_received(:call)
  end
end
