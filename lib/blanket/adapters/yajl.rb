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

      def self.post(uri, options = {}, &block)
        query = query_string options[:params]
        uri = "#{uri}?#{query}" unless query.empty?
        ::Yajl::HttpStream.post uri, options[:body], generate_options(options), &block
      end

      def self.put(uri, options = {}, &block)
        query = query_string options[:params]
        uri = "#{uri}?#{query}" unless query.empty?
        ::Yajl::HttpStream.put uri, options[:body], generate_options(options), &block
      end

      def self.delete(uri, options = {}, &block)
        query = query_string options[:params]
        uri = "#{uri}?#{query}" unless query.empty?
        ::Yajl::HttpStream.delete uri, generate_options(options), &block
      end

      private
      def self.parse_response(hash)
        [hash].flatten.map { |item| RecursiveOpenStruct.new item, recurse_over_arrays: true }
      end

      def self.generate_options(options = {})
        options.except :params, :body
      end
    end
  end
end
