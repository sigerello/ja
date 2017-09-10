require "active_support/concern"

module Ja
  module Controller
    module Utils
      module Resource
        extend ActiveSupport::Concern

      private

        def ja_resource_class
          controller_name.singularize.classify.constantize
        end

        def ja_resource_pk_param
          "#{controller_name.singularize}_pk".to_sym
        end

        def ja_type
          ja_resource_class.ja_type
        end

        def ja_resource_scope
          ja_resource_class
        end

        def ja_options
          return @ja_options if defined? @ja_options
          @ja_options = {}
        end
      end
    end
  end
end
