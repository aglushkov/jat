# frozen_string_literal: true

RSpec.describe Jat::AttributeParams::Checks::Name do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: {}, block: nil } }

  it 'calls other validations' do
    allow(Jat::AttributeParams::Checks::NameFormat).to receive(:call).with(params)

    check.(params)

    expect(Jat::AttributeParams::Checks::NameFormat).to have_received(:call)
  end
end
