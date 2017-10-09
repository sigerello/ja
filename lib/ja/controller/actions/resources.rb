require "active_support/concern"

module Ja
  module Controller
    module Actions
      module Resources
        extend ActiveSupport::Concern

        included do
          before_action :ja_find_resource, only: [:show, :update, :destroy]
        end

        def index
          @ja_resources_collection = ja_resource_scope
          @ja_resources_collection = ja_apply_preload(@ja_resources_collection)
          @ja_resources_collection = ja_apply_sort(@ja_resources_collection)
          @ja_resources_collection = ja_apply_pagination(@ja_resources_collection)

          resource_objects = @ja_resources_collection.map{ |rec| rec.ja_resource_object(ja_context) }
          included_resources = ja_resource_class.ja_included_resource_objects(@ja_resources_collection, ja_context)

          result = {}
          result[:meta] = { total_entries: @ja_resources_collection.total_entries }
          result[:data] = resource_objects
          result[:included] = included_resources unless included_resources.blank?
          render status: 200, json: result
        end

        def show
          resource_object = @ja_resource.ja_resource_object(ja_context)
          included_resources = ja_resource_class.ja_included_resource_objects(@ja_resource, ja_context)

          # _debug "JA_PRELOAD", ja_resource_class.ja_preload(ja_context)
          # _debug "JA_INCLUDE_MAP", ja_resource_class.ja_include_map!(ja_context)

          result = {}
          result[:data] = resource_object
          result[:included] = included_resources unless included_resources.blank?
          render status: 200, json: result
        end

        def create
          # TODO: implement
          render status: 200, json: params
        end

        def update
          # TODO: implement
          render status: 200, json: params
        end

        def destroy
          # TODO: implement
          render status: 200, json: params
        end

      private

        def ja_find_resource
          @ja_resource = ja_resource_scope
          @ja_resource = ja_apply_preload(@ja_resource)
          @ja_resource = @ja_resource.find_by!(ja_resource_class.ja_pk => params[ja_resource_pk_param])
        end

        def ja_apply_preload(scope)
          scope.preload(scope.ja_preload(ja_context))
        end

        def ja_apply_sort(scope)
          scope.order(ja_context[:sort])
        end

        def ja_apply_pagination(scope)
          scope.paginate(ja_context[:pagination])
        end

      end
    end
  end
end
