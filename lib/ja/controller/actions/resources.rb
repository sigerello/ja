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
          options = { fields: @ja_fields, include: @ja_include }

          # TODO: make sure there is no duplicates in response
          # self.ja_resources_map << self.ja_resource_uid unless self.ja_resources_map.include?(self.ja_resource_uid)

          result = {}
          result[:data] = @ja_resources_collection.map{ |rec| rec.ja_resource_object(options) }
          result[:included] = @ja_resources_collection.map{ |rec| rec.ja_included_resource_objects(options) }.flatten
          render status: 200, json: result
        end

        def show
          options = { fields: @ja_fields, include: @ja_include }

          # TODO: make sure there is no duplicates in response
          # self.ja_resources_map << self.ja_resource_uid unless self.ja_resources_map.include?(self.ja_resource_uid)

          result = {}
          result[:data] = @ja_resource.ja_resource_object(options)
          result[:included] = @ja_resource.ja_included_resource_objects(options)
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
