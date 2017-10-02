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

          ja_options[:include] = inc
        end

      end
    end
  end
end
