require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Filters
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_filters
        end

      private

        def ja_set_filters
          # TODO: implement
        end

      end
    end
  end
end
