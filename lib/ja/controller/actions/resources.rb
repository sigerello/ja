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

          result = ja_result(@ja_resources_collection, ja_context)
          render status: 200, json: result
        end

        def show
          result = ja_result(@ja_resource, ja_context)
          render status: 200, json: result
        end

        def create
          # TODO: check specs
          # TODO: slice attributes - pass only allowed attributes
          permitted_params = params.require(:data).permit(:id, :type, attributes: {})
          @ja_resource = ja_resource_scope.new(permitted_params[:attributes])
          @ja_resource[ja_resource_class.ja_pk] = permitted_params[:id]
          ok = @ja_resource.save

          # TODO: check pointer_path
          halt! status: 422, errors: @ja_resource.ja_error_objects(pointer_path: "") unless ok

          # TODO: check return object
          result = ja_result(@ja_resource, ja_context)
          render status: 201, json: result
        end

        def update
          # TODO: check specs
          # TODO: slice attributes - pass only allowed attributes
          permitted_params = params.require(:data).permit(:id, :type, attributes: {})
          ok = @ja_resource.update(permitted_params[:attributes])

          # TODO: check pointer_path
          halt! status: 422, errors: @ja_resource.ja_error_objects(pointer_path: "") unless ok

          # TODO: check return object
          result = ja_result(@ja_resource, ja_context)
          render status: 200, json: result
        end

        def destroy
          @ja_resource.destroy
          result = ja_result(@ja_resource, ja_context)
          render status: 200, json: result
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

        def ja_result(res, context = {})
          result = {}

          if res.class <= ActiveRecord::Relation || res.class <= Array
            resource_objects = res.map{ |rec| rec.ja_resource_object(context) }
            result[:meta] = { total_entries: res.total_entries } if res.respond_to?(:total_entries)
            result[:data] = resource_objects
          elsif res.class <= ActiveRecord::Base
            resource_object = res.ja_resource_object(context)
            result[:data] = resource_object
          else
            return nil
          end

          included_resources = ja_resource_class.ja_included_resource_objects(res, context)
          result[:included] = included_resources unless included_resources.blank?

          result
        end

      end
    end
  end
end
