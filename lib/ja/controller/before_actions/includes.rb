require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Includes
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_includes
        end

      private

        def ja_set_includes
          # TODO: implement
          # _debug "before_action: check include params"
        end

      end
    end
  end
end
