require_relative 'base'
require 'rest_client'

module Blanket
  module Adapters
    class RestClient < Base
      def self.get(uri, options = {}, &block)
        JSON.parse ::RestClient.get(uri, options)
      end

      private
      def self.generate_options(options = {})
      end
    end
  end
end
