require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Pagination
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_pagination
        end

      private

        def ja_set_pagination
          # TODO: implement
          # _debug "before_action: check pagination params"
        end

      end
    end
  end
end
