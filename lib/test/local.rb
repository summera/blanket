require 'blanket/wrap'
require 'pry'

Dir["#{File.dirname(__FILE__)}/representers/**/*.rb"].each { |f| load(f) }
# Dir["#{File.dirname(__FILE__)}/jobs/**/*.rb"].each { |f| load(f) }

module Blanket
  module Test
    class Foo
      include Wrap

      uri 'http://localhost:3000/v1/groups'
    end

    class Local
      include Wrap

      uri 'http://localhost:3000'
      header :test, 'YO'
      # param :per_page, 1
      # extension :json
      # adapter :yajl
      before_request :beforehand, actions: [:get], path: //
      after_request :afterwards, path: //

      # Default path is /^$/
      # Default actions are all actions

      # representer V1::GroupRepresenter, path: /\/v1\/groups/
      # background V1::GroupsJob, path: '/v1/groups'
      # before_request :some_method, path: '/v1/groups', only: [:get]

      # Delegate to class when performing http action
      # delegate_action :get, to: Foo, path: //, options: {  params: { per_page: 1 } }

      def beforehand(action)
        puts 'this is before'
      end

      def afterwards(response, action)
        puts 'this is after'
      end
    end
  end
end
