# frozen_string_literal: true

RSpec.describe Jat::Opts::Checks::NameFormat do
  let(:check) { described_class }
  let(:params) { { name: name, opts: {}, block: nil } }
  let(:name) { :name }

  it 'allows only symbol or string as name' do
    params[:name] = :name
    expect { check.(params) }.not_to raise_error

    params[:name] = 'name'
    expect { check.(params) }.not_to raise_error

    params[:name] = nil
    expect { check.(params) }.to raise_error Jat::Error, /name/

    params[:name] = {}
    expect { check.(params) }.to raise_error Jat::Error, /name/
  end

  it 'does not allow empty name' do
    params[:name] = :''
    expect { check.(params) }.to raise_error Jat::Error, /name/

    params[:name] = ''
    expect { check.(params) }.to raise_error Jat::Error, /name/
  end

  it 'does not allow to add names starting or ending with - or _' do
    params[:name] = '-foo'
    expect { check.(params) }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = 'foo-'
    expect { check.(params) }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = '_foo'
    expect { check.(params) }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = 'foo_'
    expect { check.(params) }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = '_'
    expect { check.(params) }.to raise_error Jat::Error, /'-' or '_'/

    params[:name] = '-'
    expect { check.(params) }.to raise_error Jat::Error, /'-' or '_'/
  end

  it 'allows name with a-z, A-Z, 0-9, `-` and `_`' do
    part1 = ('a'..'z').to_a.join
    part2 = ('A'..'Z').to_a.join
    part3 = (0..9).to_a.join
    params[:name] = "#{part1}-#{part2}_#{part3}"
    expect { check.(params) }.not_to raise_error
  end

  it 'does not allow name with non a-z, A-Z, 0-9, `-` and `_` symbols' do
    params[:name] = 'a#bc'
    expect { check.(params) }.to raise_error Jat::Error, /A-Z/
  end
end
