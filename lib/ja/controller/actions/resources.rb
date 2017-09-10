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
          @ja_resources_collection = @ja_resources_collection.preload(ja_options[:preload_map])
          @ja_resources_collection = ja_apply_sort(@ja_resources_collection, ja_options[:sort])
          @ja_resources_collection = ja_apply_pagination(@ja_resources_collection, ja_options[:pagination])

          resource_objects = @ja_resources_collection.map{ |rec| rec.ja_resource_object(ja_options) }
          included_resources = ja_resource_class.ja_included_resource_objects(@ja_resources_collection, ja_options)

          _debug ja_options

          result = {}
          result[:meta] = { total_entries: @ja_resources_collection.total_entries }
          result[:data] = resource_objects
          result[:included] = included_resources unless included_resources.blank?
          render status: 200, json: result
        end

        def show
          resource_object = @ja_resource.ja_resource_object(ja_options)
          included_resources = ja_resource_class.ja_included_resource_objects(@ja_resource, ja_options)

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
          @ja_resource = @ja_resource.preload(ja_options[:preload_map])
          @ja_resource = @ja_resource.find_by!(ja_resource_class.ja_pk => params[ja_resource_pk_param])
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
