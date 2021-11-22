# frozen_string_literal: true

module Flexitime
  PRECISIONS = [:day, :hour, :min, :sec, :usec].freeze
  DATE_PARTS = [:day, :month].freeze

  class Configuration
    # = Configuration options
    #
    # == time_class
    # The time class used to create the Time object
    # defaulting to Time which will use the system local time zone.
    # This can be set to ActiveSupport::TimeZone to create a Time object
    # using the specified time zone
    #
    #   Time.zone = "Europe/London"
    #   Flexitime.time_class = Time.zone
    #   Flexitime.parse("01/06/2021 17:00") # => Tue, 01 Jun 2021 17:00:00.000000000 BST +01:00
    #
    # == first_date_part
    # The first part of the date within the string, either :day or :month
    # This can be set manually otherwise when using the rails-I18n gem if the first element
    # of the "date.order" translation is :day or :month that will be used
    # otherwise the default of :day will be used
    #
    #   Flexitime.first_date_part = :day
    #   Flexitime.parse("01/06/2021") # => 2021-06-01 00:00:00 +0100
    #
    #   Flexitime.first_date_part = :month
    #   Flexitime.parse("01/06/2021") # => 2021-01-06 00:00:00 +0100
    #
    # Regardless of the option value, the gem will always attempt to parse
    # a string starting with a 4 digit year, deciphering the format as year/month/day
    #
    #   Flexitime.parse("2021-11-12 08:15") # => 2021-11-12 08:15:00 +0000
    #
    # == precision
    # The desired precision for the returned Time object, defaulting to minute (:min)
    #
    #   Flexitime.parse("01/06/2021 18:30:45.036711") # => 2021-06-01 18:30:00 +0100
    #   Flexitime.precision = :sec
    #   Flexitime.parse("01/06/2021 18:30:45.036711") # => 2021-06-01 18:30:45 +0100
    #   Flexitime.precision = :usec
    #   Flexitime.parse("01/06/2021 18:30:45.036711") # => 2021-06-01 18:30:45.036711 +0100
    #
    # == ambiguous_year_future_bias
    # The option used to determine the century when parsing a string containing a 2 digit year
    # with the default value of 50 and the current year of 2020
    # the year is set from within a range of >= 1970 and <= 2069
    # whereas with a value of 20 and the current year of 2020
    # the year is set from within a range of >= 2000 and <= 2099
    #
    #   Flexitime.parse("01/08/00").year # => 2000
    #   Flexitime.parse("01/08/69").year # => 2069
    #   Flexitime.parse("01/08/70").year # => 1970
    #   Flexitime.parse("01/08/99").year # => 1999
    #
    attr_accessor :time_class
    attr_reader :precision
    attr_accessor :ambiguous_year_future_bias

    def initialize
      @time_class = ::Time
      @first_date_part = nil
      @precision = :min
      @ambiguous_year_future_bias = 50
    end

    def first_date_part=(first_date_part)
      raise ArgumentError.new("Invalid first date part") unless first_date_part_valid?(first_date_part)
      @first_date_part = first_date_part.to_sym
    end

    def first_date_part
      first_date_part = @first_date_part || i18n_first_date_part
      first_date_part_valid?(first_date_part) ? first_date_part : DATE_PARTS.first
    end

    def precision=(precision)
      raise ArgumentError.new("Invalid precision") unless precision_valid?(precision)
      @precision = precision.to_sym
    end

    private

    def i18n_first_date_part
      Array(I18n.t("date.order")).map(&:to_sym).first if defined?(I18n)
    end

    def first_date_part_valid?(first_date_part)
      first_date_part.present? && DATE_PARTS.include?(first_date_part.to_s.to_sym)
    end

    def precision_valid?(precision)
      precision.present? && PRECISIONS.include?(precision.to_s.to_sym)
    end
  end
end
