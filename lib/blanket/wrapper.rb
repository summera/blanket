require_relative "utils"
require 'active_support/inflector'

module Blanket
  class Wrapper
    class << self
      private
      # @macro [attach] REST action
      #   @method $1()
      #   Performs a $1 request on the wrapped URL
      #   @param [String, Symbol, Numeric] id The resource identifier to attach to the last part of the request
      #   @param [Hash] options An options hash with values for :headers, :extension, :params and :body
      #   @return [Blanket::Response, Array] A wrapped Blanket::Response or an Array
      def add_action(action)
        define_method(action) do |id=nil, options={}, &block|
          request(action, id, options, &block)
        end
      end
    end

    # Attribute accessor for HTTP Headers that
    # should be applied to all requests
    attr_accessor :headers

    # Attribute accessor for  params that
    # should be applied to all requests
    attr_accessor :params

    # Attribute accessor for file extension that
    # should be appended to all requests
    attr_accessor :extension

    attr_accessor :adapter

    add_action :get
    add_action :post
    add_action :put
    add_action :patch
    add_action :delete

    # Wraps the base URL for an API
    # @param [String, Symbol] base_uri The root URL of the API you wish to wrap.
    # @param [Hash] options An options hash with global values for :headers, :extension and :params
    # @return [Blanket] The Blanket object wrapping the API
    def initialize(base_uri, options={})
      @base_uri = base_uri
      @uri_parts = []
      @headers = options[:headers] || {}
      @params = options[:params] || {}
      @extension = options[:extension]
      @adapter = options[:adapter] || :httparty
    end

    private

    def method_missing(method, *args, &block)
      Wrapper.new uri_from_parts([method, args.first]), {
        headers: @headers,
        extension: @extension,
        params: @params
      }
    end

    def request_options(options={})
      new_options = options.dup
      new_options[:headers] = Blanket
        .stringify_keys merged_headers(new_options.delete(:headers))

      new_options[:params] = merged_params new_options.delete(:params)
      new_options.reject { |_, value| value.nil? || value.empty? }
    end

    def classify_adapter
      require_relative "adapters/#{adapter}"
      Blanket::Adapters.const_get "#{adapter}".classify
    end

    def request(method, id=nil, options={}, &block)
      if id.is_a? Hash
        options = id
        id = nil
      end

      uri = uri_from_parts([id])

      if @extension
        uri = "#{uri}.#{extension}"
      end

      classified_adapter = classify_adapter

      classified_adapter.public_send(
        method,
        uri,
        request_options(options),
        &block
      )

      # if response.code <= 400
      #   body = (response.respond_to? :body) ? response.body : nil
      #   (body.is_a? Array) ? body.map(Response.new) : Response.new(body)
      # else
      #   raise Blanket::Exceptions.generate_from_response(response)
      # end
    end

    def merged_headers(headers)
      @headers.merge(headers || {})
    end

    def merged_params(params)
      @params.merge(params || {})
    end

    def uri_from_parts(parts)
      File.join @base_uri, *parts.compact.map(&:to_s)
    end
  end
end
