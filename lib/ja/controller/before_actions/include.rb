require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Include
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_include
        end

      private

        def ja_include
          ja_resource_class.ja_include
        end

        def ja_restricted_include
          ja_resource_class.ja_restricted_include
        end

        # TODO: consider to raise errors when user requests restricted includes
        def ja_set_include
          inc = params[:include].split(",") rescue nil
          inc = ja_include if inc.nil?
          inc = inc.map(&:to_s) - ja_restricted_include.map(&:to_s)

          ja_options[:include_map] = inc.inject({}) { |res, path| ja_build_include_map!(res, ja_resource_class.new, path); res }
          ja_options[:include] = inc
          ja_options[:preload_map] = inc.map { |path| ja_build_preload_map!(path) }
        end

        # TODO: format proper error response
        def ja_build_include_map!(res = {}, obj, path)
          paths = path.split(".")
          if paths.size == 1
            if obj.respond_to?(paths[0])
              res[obj.class.ja_type] ||= []
              res[obj.class.ja_type] << paths[0].to_sym unless res[obj.class.ja_type].include?(paths[0].to_sym)
            else
              raise Ja::Error::InvalidIncludeParam.new(nil, obj.class, paths[0]) unless obj.respond_to?(paths[0])
            end
          elsif paths.size > 1
            ja_build_include_map!(res, obj, paths[0])
            obj = obj.class.ja_relationships.select{ |r| r[:name].to_s == paths[0] }[0][:klass].new
            ja_build_include_map!(res, obj, paths[1..-1].join("."))
          end
        end

        def ja_build_preload_map!(path)
          paths = path.split(".")
          if paths.size == 1
            path.to_sym
          elsif paths.size > 1
            { paths[0].to_sym => ja_build_preload_map!(paths[1..-1].join(".")) }
          end
        end

      end
    end
  end
end
