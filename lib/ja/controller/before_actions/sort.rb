require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Sort
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_sort
        end

      private

        def ja_set_sort
          # TODO: implement
          # _debug "before_action: check sort params"
        end

      end
    end
  end
end
