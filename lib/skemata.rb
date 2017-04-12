# frozen_string_literal: true

require 'skemata/version'
require 'active_support'
require 'active_support/core_ext'

module Skemata
  extend ActiveSupport::Autoload

  autoload :DSL
  autoload :Node

  def self.draw(type, root_object, &block)
    DSL.draw({ type: type, root_object: root_object }, &block)
  end
end
