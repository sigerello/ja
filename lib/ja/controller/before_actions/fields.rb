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
          unless params[:fields].blank?
            fields = {}
            params[:fields].each { |k,v| fields[k.to_sym] = v.split(",").map(&:to_sym) } rescue nil
            ja_context[:fields] = fields unless fields.blank?
          end
        end

      end
    end
  end
end
