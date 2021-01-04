# frozen_string_literal: true

RSpec.describe Jat::Attribute do
  let(:jat) { Class.new(Jat) }

  it 'stores and refreshes initial opts' do
    opts = instance_double(
      Jat::Opts,
      block: :old_block,
      exposed?: :old_exposed,
      preloads_with_path: %i[old_preloads old_path],
      key: :old_key,
      many?: :old_many,
      name: :old_name,
      original_name: :old_original_name,
      relation?: :old_relation,
      serializer: :old_serializer
    )
    allow(Jat::Opts).to receive(:new).with('JAT_CLASS', 'PARAMS').and_return(opts)
    attribute = described_class.new('JAT_CLASS', 'PARAMS')

    allow(opts).to receive(:block).and_return(:new_block)
    allow(opts).to receive(:exposed?).and_return(:new_exposed)
    allow(opts).to receive(:preloads_with_path).and_return(%i[new_preloads new_path])
    allow(opts).to receive(:key).and_return(:new_key)
    allow(opts).to receive(:many?).and_return(:new_many)
    allow(opts).to receive(:name).and_return(:new_name)
    allow(opts).to receive(:original_name).and_return(:new_original_name)
    allow(opts).to receive(:relation?).and_return(:new_relation)
    allow(opts).to receive(:serializer).and_return(:new_serializer)

    # Check stored old values
    expect(attribute.block).to eq :old_block
    expect(attribute.exposed).to eq :old_exposed
    expect(attribute.preloads).to eq(:old_preloads)
    expect(attribute.preloads_path).to eq(:old_path)
    expect(attribute.key).to eq :old_key
    expect(attribute.many).to eq :old_many
    expect(attribute.name).to eq :old_name
    expect(attribute.original_name).to eq :old_original_name
    expect(attribute.relation).to eq :old_relation
    expect(attribute.serializer).to eq :old_serializer

    # Check has new values after refresh
    attribute.refresh

    expect(attribute.block).to eq :new_block
    expect(attribute.exposed).to eq :new_exposed
    expect(attribute.preloads).to eq(:new_preloads)
    expect(attribute.preloads_path).to eq(:new_path)
    expect(attribute.key).to eq :new_key
    expect(attribute.many).to eq :new_many
    expect(attribute.name).to eq :new_name
    expect(attribute.original_name).to eq :new_original_name
    expect(attribute.relation).to eq :new_relation
    expect(attribute.serializer).to eq :new_serializer
  end
end
