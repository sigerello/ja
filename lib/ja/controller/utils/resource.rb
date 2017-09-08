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
          s = ja_resource_class
          s = s.preload(ja_resource_class.ja_relationship_names)
          s
        end

        def ja_resources_map
          return @ja_resources_map if defined? @ja_resources_map
          @ja_resources_map = []
        end
      end
    end
  end
end
