require 'virtus'
require 'representable/json'
require 'representable/coercion'

module Blanket
  module Test
    module V1
    # module V1
    #   class TestCoercion < ::Virtus::Attribute
    #     def coerce(value)
    #       value.upcase
    #     end
    #   end

      class GroupRepresenter < Representable::Decorator
        include Representable::JSON
        include Representable::Coercion

        property :name
        property :video_playlists
        property :audio_playlists
        property :users
      end
    end
  end
end
