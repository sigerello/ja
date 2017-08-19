require "active_support/concern"

module Ja
  module Controller
    module Utils
      module Resource
        extend ActiveSupport::Concern

      private
        # TODO: consider using controller_name

        def ja_resource_class
          controller_name.singularize.classify.constantize
        end

        def ja_resource_pk_param
          "#{controller_name.singularize}_pk".to_sym
        end

        def ja_resource_scope
          ja_resource_class
        end

      end
    end
  end
end
