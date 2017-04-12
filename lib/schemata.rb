# frozen_string_literal: true

require 'schemata/version'
require 'active_support'
require 'active_support/core_ext'

module Schemata
  extend ActiveSupport::Autoload

  autoload :Node
end
