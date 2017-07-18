require "active_support"

module Ja::Controller
  extend ActiveSupport::Concern

  included do
    $stderr.puts "Ja::Controller included into #{self}"
  end

  class_methods do
    def ja options
      $stderr.puts "Ja::Controller macro called from #{self}"
    end
  end
end
