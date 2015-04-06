require 'httparty'
require_relative 'base'

module Blanket
  module Adapters
    class Httparty < Base
      def self.get(uri, options = {}, &block)
        response = ::HTTParty.get uri, generate_options(options), &block
        response.to_hash
      end

      def self.post(uri, options = {}, &block)
        response = ::HTTParty.post uri, generate_options(options), &block
        response.to_hash
      end

      def self.put(uri, options = {}, &block)
        response = ::HTTParty.put uri, generate_options(options), &block
        response.to_hash
      end

      def self.delete(uri, options = {}, &block)
        response = ::HTTParty.delete uri, generate_options(options), &block
        response.to_hash
      end

      private
      def self.generate_options(options = {})
        new_options = options.dup
        new_options[:query] = new_options.delete :params if options[:params]
        new_options
      end
    end
  end
end
