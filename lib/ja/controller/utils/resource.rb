require "active_support/concern"

module Ja
  module Controller
    module Utils
      module Resource
        extend ActiveSupport::Concern

      private
        # TODO: consider using controller_name

        def ja_resource_class
          params[:controller].classify.constantize
        end

        def ja_resource_pk_param
          "#{params[:controller].singularize}_pk".to_sym
        end

        def ja_resource_scope
          ja_resource_class
        end

      end
    end
  end
end
