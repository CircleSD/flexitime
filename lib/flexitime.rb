# frozen_string_literal: true

require "time"
require "forwardable"

# Active Support Core Extensions
# https://guides.rubyonrails.org/active_support_core_extensions.html
require "active_support/time" # Time.zone
require "active_support/core_ext/object/blank" # blank? and present?
require "active_support/core_ext/array/access" # array second/third/fourth
require "active_support/core_ext/time/calculations" # Time.days_in_month

require_relative "flexitime/version"
require_relative "flexitime/configuration"
require_relative "flexitime/parser"

module Flexitime
  class << self
    extend Forwardable
    def_delegators :configuration, :first_date_part, :precision, :ambiguous_year_future_bias
    def_delegators :configuration, :first_date_part=, :precision=, :ambiguous_year_future_bias=

    include Flexitime::Parser

    def configuration
      Thread.current["Flexitime.configuration"] ||= Configuration.new
    end
  end
end
