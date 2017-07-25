require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Fields
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_fields
        end

      private

        def ja_set_fields
          # TODO: implement
          # _debug "before_action: check fields params"
        end

      end
    end
  end
end
