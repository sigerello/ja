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

        def ja_pagination
          { page: 1, per_page: ja_resource_class.per_page }
        end

        def ja_set_pagination
          params_page = {}

          params_page[:page] = params[:page][:page].to_i rescue ja_pagination[:page]
          params_page[:per_page] = params[:page][:per_page].to_i rescue ja_pagination[:per_page]

          params_page[:page] = ja_pagination[:page] unless params_page[:page] > 0
          params_page[:per_page] = ja_pagination[:per_page] unless params_page[:per_page] > 0

          ja_context[:pagination] = params_page
        end

      end
    end
  end
end
