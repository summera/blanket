require_relative 'base'
require 'yajl/http_stream'

module Blanket
  module Adapters
    class Yajl < Base
      def self.get(uri, options = {}, &block)
        query = query_string options[:params]
        uri = "#{uri}?#{query}" unless query.empty?
        ::Yajl::HttpStream.get uri, generate_options(options), &block
      end

      private
      def self.parse_response(hash)
        [hash].flatten.map { |item| RecursiveOpenStruct.new item, recurse_over_arrays: true }
      end

      def self.generate_options(options = {})
        new_options = options.dup
        new_options.delete :params if options[:params]
        new_options
      end
    end
  end
end
