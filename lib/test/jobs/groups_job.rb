require 'active_job'
require 'blanket/job'

module Blanket
  module Test
    module V1
      class GroupsJob < ::ActiveJob::Base
        include Job
      end
    end
  end
end
