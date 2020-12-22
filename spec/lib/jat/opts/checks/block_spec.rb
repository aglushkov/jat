# frozen_string_literal: true

RSpec.describe Jat::Opts::Checks::Block do
  let(:check) { described_class }
  let(:params) { { name: nil, opts: {}, block: nil } }

  it 'allows 0, 1 or 2 arguments in block' do
    params[:block] = -> {}
    expect { check.(params) }.not_to raise_error

    params[:block] = ->(a) {}
    expect { check.(params) }.not_to raise_error

    params[:block] = ->(a, b) {}
    expect { check.(params) }.not_to raise_error

    params[:block] = ->(a = 1, b = 2) {}
    expect { check.(params) }.not_to raise_error

    params[:block] = ->(a, b, c) {}
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = ->(a, b:) {}
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = ->(a, *b) {}
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = proc { |a| }
    expect { check.(params) }.not_to raise_error

    params[:block] = proc { |a, b| }
    expect { check.(params) }.not_to raise_error

    params[:block] = proc { |a = 1, b = 2| }
    expect { check.(params) }.not_to raise_error

    params[:block] = proc { |a, b, c| }
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = proc { |a, b:| }
    expect { check.(params) }.to raise_error Jat::Error, /block/i

    params[:block] = proc { |a, *b| }
    expect { check.(params) }.to raise_error Jat::Error, /block/i
  end
end
