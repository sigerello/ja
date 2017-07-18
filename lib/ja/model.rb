require "active_support"

module Ja::Model
  extend ActiveSupport::Concern

  included do
    class_exec do
      def to_ja_hash options
        $stderr.puts "to_ja_hash called"
      end
    end
  end
end
