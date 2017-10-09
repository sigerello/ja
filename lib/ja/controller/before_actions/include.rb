require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Include
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_include
        end

      private

        def ja_set_include
          inc = params[:include].split(",") rescue []
          ja_context[:include] = inc unless inc.blank?
        end

      end
    end
  end
end
