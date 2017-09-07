require "active_support/concern"

module Ja
  module Controller
    module Actions
      module Resources
        extend ActiveSupport::Concern
        # TODO: check params (*_pk)

        included do
          before_action :ja_find_resource, only: [:show, :update, :destroy]
        end

        def index
          @ja_resources_collection = ja_resource_scope
          @ja_resources_collection = ja_apply_sort(@ja_resources_collection, @ja_sort)
          @ja_resources_collection = ja_apply_pagination(@ja_resources_collection, @ja_pagination)
          options = { fields: @ja_fields }
          ja_render_data data: @ja_resources_collection.map{ |rec| rec.ja_resource_object(options) }
        end

        def show
          options = { fields: @ja_fields }
          ja_render_data data: @ja_resource.ja_resource_object(options)
        end

        def create
          ja_render_params
        end

        def update
          ja_render_params
        end

        def destroy
          ja_render_params
        end

      private

        def ja_find_resource
          @ja_resource = ja_resource_scope.find_by!(ja_resource_class.ja_pk => params[ja_resource_pk_param])
        end

        def ja_apply_sort(collection, v)
          collection.order(v)
        end

        def ja_apply_pagination(collection, v)
          collection.paginate(v)
        end

      end
    end
  end
end
