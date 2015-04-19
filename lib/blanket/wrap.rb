require_relative "utils"
require 'active_support/inflector'
require 'active_support/concern'

module Blanket
  module Wrap
    extend ActiveSupport::Concern

    module ClassMethods
      attr_accessor :after_requests,
        :before_requests,
        :background_actions

      attr_reader :base_headers,
        :base_uri,
        :base_params,
        :base_extension,
        :base_adapter,
        :base_representer,
        :base_background_job,
        :base_representers

      def uri(u)
        @base_uri = u
      end

      def header(key, val)
        @base_headers[key] = val
      end

      def param(key, val)
        @base_params[key] = val
      end

      def extension(val)
        @base_extension = val
      end

      def adapter(a)
        @base_adapter = a
      end

      def representer(klass, options = {})
        path = options[:path] || []
        actions = [:get, :post, :put, :delete]
        self.base_representers[path] = { :representer => klass, :actions => actions }
      end

      # def background_job(j)
      #   @base_background_job = j
      # end

      def before_request(callback, *actions)
        self.before_requests << { :callback => callback, :actions => actions }
      end

      def after_request(callback, *actions)
        self.after_requests << { :callback => callback, :actions => actions }
      end

      def perform_in_background(*actions)
        self.background_actions.push(*actions)
      end

      private
      # @macro [attach] REST action
      #   @action $1()
      #   Performs a $1 request on the wrapped URL
      #   @param [String, Symbol, Numeric] id The resource identifier to attach to the last part of the request
      #   @param [Hash] options An options hash with values for :headers, :extension, :params and :body
      #   @return [Blanket::Response, Array] A wrapped Blanket::Response or an Array
      def add_action(action)
        define_method(action) do |id = nil, options = {}, &block|
          if id.is_a? Hash
            options = id
            id = nil
          end

          @path = path_from_parts id

          request action, options, &block
        end
      end
    end

    included do
      # Class instance var instantiation
      @base_headers = {}
      @base_params = {}
      @base_representers = {}
      @before_requests = []
      @after_requests = []
      @background_actions = []

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
      attr_accessor :representer
      attr_reader :path

      add_action :get
      add_action :post
      add_action :put
      add_action :patch
      add_action :delete
    end

    # Wraps the base URL for an API
    # @param [String, Symbol] base_uri The root URL of the API you wish to wrap.
    # @param [Hash] options An options hash with global values for :headers, :extension and :params
    # @return [Blanket] The Blanket object wrapping the API
    def initialize(base_uri = nil, options = {})
      @base_uri = base_uri || self.class.base_uri
      # @uri_parts = []
      @headers = self.class.base_headers.merge options[:headers] || {}
      @params = self.class.base_params.merge options[:params] || {}
      @extension = options[:extension] || self.class.base_extension
      @adapter = options[:adapter] || self.class.base_adapter || :httparty
      @representer = options[:representer] || base_representer
      @path = options[:path] || ''
    end

    private
    def method_missing(method, *args, &block)
      if self.class.before_requests.any? { |h| h[:callback] == method }
        raise "Missing callback #{method}"
      end

      if self.class.after_requests.any? { |h| h[:callback] == method }
        raise "Missing callback #{method}"
      end

      binding.pry

      self.class.new @base_uri, {
        headers: @headers,
        extension: @extension,
        params: @params,
        path: path_from_parts(method, args.first)
      }
    end

    def request(action, options = {}, &block)
      # return push_to_background(action, options, &block) if perform_in_background? action, options

      execute_before_requests action

      response = classify_adapter.public_send(
        action,
        uri,
        request_options(options),
        &block
      )

      if !block_given?
        response_representer = representer || base_representer(action) || infer_representer

        response = response_representer ?
          response_representer.prepare(RecursiveOpenStruct.new(response, recurse_over_arrays: true)) :
          response

        execute_after_requests response, action

        response
      end
    end

    def base_representer
      self.class.base_representers[path]
    end

    def request_options(options = {})
      new_options = options.dup

      new_options[:headers] = Blanket
        .stringify_keys merged_headers(new_options.delete(:headers))

      new_options[:params] = merged_params new_options.delete(:params)

      new_options.reject do |_, value|
        value.nil? || value.empty? unless [true, false].include?(value)
      end
    end

    def classification_path(type)
      temp_path = path.dup
      temp_path[-1] = path.last.to_s.singularize.to_sym if type == :member
      temp_path
    end

    def classify_adapter
      require_relative "adapters/#{adapter}"
      Blanket::Adapters.const_get "#{adapter}".classify
    end

    def classify_representer(type)
      namespace = self.class.name.deconstantize
      class_path = classification_path(type)
      "#{namespace}::" << "#{class_path.join('/')}_representer".classify
    end

    # def classify_active_job(type)
    #   namespace = self.class.name.deconstantize
    #   class_path = classification_path(type)
    #   "#{namespace}::" << "#{class_path.join('/')}_job".classify
    # end

    def infer_representer(type)
      representer_class = classify_representer type

      inferred_representer = nil
      if Object.const_defined? representer_class
        inferred_representer = representer_class.constantize
      end

      inferred_representer
    end

    # def infer_active_job(type)
    #   classify_active_job(type).constantize
    # end

    def merged_headers(headers)
      @headers.merge(headers || {})
    end

    def merged_params(params)
      @params.merge(params || {})
    end

    def uri
      location = File.join @base_uri, path

      if extension
        location = "#{location}.#{extension}"
      end

      location
    end

    def path_from_parts(*parts)
      File.join(path, parts.compact.map(&:to_s)).gsub(/\/*$/, '')
    end

    def execute_before_requests(action)
      self.class.before_requests.each do |action_callback|
        if action_callback[:actions].include? action
          send action_callback[:callback], action
        end
      end
    end

    def execute_after_requests(response, action)
      self.class.after_requests.each do |action_callback|
        if action_callback[:actions].include? action
          send action_callback[:callback], response, action
        end
      end
    end

    # def perform_in_background?(action, options = {})
    #   return options[:perform_in_background] if options.has_key? :perform_in_background
    #   self.class.background_actions.include? action
    # end

    # def push_to_background(action, id = nil, options = {}, &block)
    #   # type = id ? :member : :collection
    #   # IcontactJob.perform_later to_hash.to_json, action.to_s, id, options, &block
    # end

    def to_hash
      hash = {}
      instance_variables.each do |k|
        hash[k.to_s.gsub('@', '').to_sym] = instance_variable_get k
      end

      hash
    end
  end
end
