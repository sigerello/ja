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

        def ja_fields
          ja_resource_class.ja_fields
        end

        def ja_set_fields
          params_fields = params[:fields].split(",") rescue []
          @ja_fields = params_fields.size > 0 ? params_fields : ja_fields
        end

      end
    end
  end
end
