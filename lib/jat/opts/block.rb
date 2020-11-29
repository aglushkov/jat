# frozen_string_literal: true

class Jat
  class Opts
    class Block
      class << self
        def call(original_block, delegate, key)
          return if !original_block && !delegate

          original_block ? transform(original_block) : delegate_block(key)
        end

        private

        def transform(original_block)
          return original_block if original_block.parameters.count == 2

          ->(obj, _params) { original_block.(obj) }
        end

        def delegate_block(key)
          ->(obj, _params) { obj.public_send(key) }
        end
      end
    end
  end
end
