require 'representable/json'

module Blanket
  module Test
    module V1
      class GroupsRepresenter < Representable::Decorator
        include Representable::JSON

        collection :groups, decorator: GroupRepresenter
      end
    end
  end
end
