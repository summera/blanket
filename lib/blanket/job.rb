ActiveJob::Base.queue_adapter = :inline

module Blanket
  module Job
    def json_to_instance(client_class, json)
      hash = JSON.parse(json).symbolize_keys
      client_class.constantize.new hash[:base_uri], hash
    end

    def perform(client_class, json, action, options, &block)
      action = action.to_sym
      client = json_to_instance client_class, json

      options.merge! :background => false
      client.send action, options.symbolize_keys, &block
    end
  end
end
