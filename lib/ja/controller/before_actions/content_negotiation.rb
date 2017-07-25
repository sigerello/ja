require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module ContentNegotiation
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_headers
        end

      private

        def ja_set_headers
          # TODO: implement
          # _debug "before_action: set headers"
        end

      end
    end
  end
end
