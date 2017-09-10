require "active_support/concern"

module Ja
  module Controller
    module BeforeActions
      module Sort
        extend ActiveSupport::Concern

        included do
          before_action :ja_set_sort
        end

      private

        def ja_sort
          ja_resource_class.ja_sort
        end

        def ja_set_sort
          params_sort = params[:sort].split(",") rescue []
          params_sort.map! { |s| s.starts_with?("-") ? { s[1..-1] => :desc } : { s => :asc } }
          params_sort.reject!{ |rec| !ja_resource_class.column_names.include?(rec.keys[0]) }
          params_sort.map!{ |rec| rec.symbolize_keys }

          ja_options[:sort] = params_sort.size > 0 ? params_sort : ja_sort
        end

      end
    end
  end
end
