require "active_support/concern"

module Ja
  module Controller
    module Utils
      module Render
        extend ActiveSupport::Concern

      private

        def ja_render_data data={}
          data[:status] ||= 200
          render json: { data: data[:data] }, status: data[:status]
        end

        # TODO: remove
        def ja_render_params
          ja_render_data params: params
        end

      end
    end
  end
end
