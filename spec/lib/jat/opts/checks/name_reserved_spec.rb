# frozen_string_literal: true

RSpec.describe Jat::Opts::Checks::NameReserved do
  let(:check) { described_class }
  let(:params) { { name: :name, opts: {}, block: nil } }
  let(:name) { :name }

  it 'does not allow `type` name' do
    params[:name] = :type
    expect { check.(params) }.to raise_error Jat::Error, /type/

    params[:name] = 'type'
    expect { check.(params) }.to raise_error Jat::Error, /type/
  end

  it 'does not allow `id` name' do
    params[:name] = :id
    expect { check.(params) }.to raise_error Jat::Error, /id/

    params[:name] = 'id'
    expect { check.(params) }.to raise_error Jat::Error, /id/
  end
end
