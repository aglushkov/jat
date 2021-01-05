# frozen_string_literal: true

RSpec.describe Jat::AttributeParams::Validate do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: {}, block: nil } }

  it 'calls other validations' do
    allow(Jat::AttributeParams::Checks::Name).to receive(:call).with(params)
    allow(Jat::AttributeParams::Checks::Opts).to receive(:call).with(params)
    allow(Jat::AttributeParams::Checks::Block).to receive(:call).with(params)

    check.(params)

    expect(Jat::AttributeParams::Checks::Name).to have_received(:call)
    expect(Jat::AttributeParams::Checks::Opts).to have_received(:call)
    expect(Jat::AttributeParams::Checks::Block).to have_received(:call)
  end
end
