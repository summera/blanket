require_relative 'base'

module Blanket
  module Adapters
    class Httparty < Base
      def self.get(uri, options = {}, &block)
        response = ::HTTParty.get uri, generate_options(options), &block
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
