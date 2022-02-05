# frozen_string_literal: true

require_relative "./lib/format_user_preloads"
require_relative "./lib/preloads_with_path"

class Jat
  module Plugins
    # Base (core) plugin for :json_api_preloads and :simple_api_preloads.
    # Adds Attribute#preloads, Attribute#preloads_path methods.
    module BasePreloads
      def self.plugin_name
        :base_preloads
      end

      def self.load(serializer_class, **_opts)
        serializer_class::Attribute.include(AttributeMethods)
      end

      module AttributeMethods
        NULL_PRELOADS = [nil, [].freeze].freeze

        def preloads
          return @preloads if defined?(@preloads)

          @preloads, @preloads_path = get_preloads_with_path
          @preloads
        end

        def preloads_path
          return @preloads_path if defined?(@preloads_path)

          @preloads, @preloads_path = get_preloads_with_path
          @preloads_path
        end

        # When provided multiple values in preloads, such as { user: [:profile] },
        # we don't know which entity is main (:user or :profile in this example) but
        # we need to know main value to add nested preloads to it.
        # User can specify main preloaded entity by adding "!" suffix
        # ({ user!: [:profile] } for example), otherwise the latest key will be considered main.
        def get_preloads_with_path
          preloads_provided = opts.key?(:preload)
          preloads =
            if preloads_provided
              opts[:preload]
            elsif relation?
              key
            end

          # Nulls and empty hash differs as we can preload nested results to
          # empty hash, but we will skip nested preloading if null or false provided
          return NULL_PRELOADS if preloads_provided && !preloads

          preloads = FormatUserPreloads.to_hash(preloads)
          preloads, path = PreloadsWithPath.call(preloads)

          [Utils::EnumDeepFreeze.call(preloads), path.freeze]
        end
      end
    end

    register_plugin(BasePreloads.plugin_name, BasePreloads)
  end
end
