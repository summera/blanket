require 'blanket/response'
require 'httparty'

module Blanket
  module Adapters
    class Base
      def self.query_string(params = {})
        HTTParty::Request::NON_RAILS_QUERY_STRING_NORMALIZER.call params
      end

      private
      def self.generate_options(options = {})
        options
      end

      def self.parse_response(json_string)
        Response.new json_string
      end
    end
  end
end
