# frozen_string_literal: true

module Flexitime
  module Parser
    # date regex to match year/month/day eg. "2021-10-27"
    # with 4 digit year; 1 or 2 digit month & day; and slash, hyphen or period separator
    ISO8601_DATE_REGEX = %r{(?<!\d)(\d{4})[-./](\d{1,2})[-./](\d{1,2})(?!\d)}
    # date regex to match day/month/year and month/day/year eg. "27/10/2021" and "10/27/2021"
    # with 1 or 2 digit day & month; 2 or 4 digit year; and slash, hyphen or period separator
    LOCAL_DATE_REGEX = %r{(?<!\d)(\d{1,2})[-./](\d{1,2})[-./](\d{4}|\d{2})(?!\d)}
    # time regex to match a zulu time "11:14:30.000Z"
    # with 2 digit hour, minute & second; 1 to 6 digit milliseconds; and Z character
    ISO8601_TIME_REGEX = %r{(\d{2}):(\d{2}):(\d{2})\.(\d{1,6})(Z{1})$}
    # time regex to match hour/min/sec eg. "09:15:30", "09:15:30 AM" and "09:15:30AM"
    # with 1 or 2 digit hour; 2 digit minute & second; optional case-insensitive meridiem;
    # and colon separator but not a period separator as there are no rails-i18n locales
    # using that separator with hours, minutes & seconds and it would clash with the local date pattern
    HOUR_MINUTE_SECOND_REGEX = %r{^(\d{1,2}):(\d{2}):(\d{2})\s?([aApP][mM])?\.?$}
    # time regex to match hour/min eg. "09:15", "09:15 AM" and "09:15AM"
    # with 1 or 2 digit hour; 2 digit minute; optional case-insensitive meridiem;
    # and colon or period separator as in rails-i18n there a few locales (such as Danish)
    # that use a period with hours & minutes
    HOUR_MINUTE_REGEX = %r{^(\d{1,2})[:.](\d{2})\s?([aApP][mM])?\.?$}

    # Parse a String argument and create a Time object
    # using the configuration time class and desired precision.
    #
    # When the String contains a date or date/time or time that matches the regular expressions
    # the time class local method is used to create a Time object
    # otherwise the time class parse method is used to create a Time object
    # and for an invalid date, date/time or time nil is returned.
    def parse(str)
      str = str.is_a?(String) ? str : str.try(:to_str)
      return nil if str.blank?

      parts = extract_parts(str)

      if parts.present?
        create_time_from_parts(parts) if valid_date_parts?(parts)
      else
        time_class_parse(str)
      end
    end

    private

    # Extract date and time parts and return a Hash containing the parts
    # or nil if either the date or time string does not match a regex
    def extract_parts(str)
      date_str, time_str = separate_date_and_time(str)

      date_parts = extract_date_parts(date_str)

      if date_parts.blank?
        now = Flexitime.configuration.time_class.now
        date_parts = {year: now.year, month: now.month, day: now.day}
        time_str = str.strip
      end

      if time_str.present?
        time_parts = extract_time_parts(time_str)
        return nil if time_parts.blank?
        date_parts.merge(time_parts)
      else
        date_parts
      end
    end

    def separate_date_and_time(str)
      parts = str.index(" ").present? ? str.split(" ") : str.split("T")
      [parts.shift, parts.join(" ")]
    end

    def extract_date_parts(str)
      extract_iso_date_parts(str) || extract_local_date_parts(str)
    end

    def extract_iso_date_parts(str)
      # match array returns ["1973-08-23", "1973", "08", "23"]
      parts = str.match(ISO8601_DATE_REGEX).to_a.pop(3).map(&:to_i)
      if parts.present?
        {year: make_year(parts.first), month: parts.second, day: parts.third}
      end
    end

    def extract_local_date_parts(str)
      # match array returns ["23-08-1973", "23", "08", "1973"]
      parts = str.match(LOCAL_DATE_REGEX).to_a.pop(3).map(&:to_i)
      if parts.present?
        day, month = Flexitime.configuration.first_date_part == :day ? [parts.first, parts.second] : [parts.second, parts.first]
        {year: make_year(parts.third), month: month, day: day}
      end
    end

    def extract_time_parts(str)
      extract_iso_time_parts(str) || extract_hour_minute_second_parts(str) || extract_hour_minute_parts(str)
    end

    def extract_iso_time_parts(str)
      # match array returns ["11:14:30.999Z", "11", "14", "30", "999", "Z"]
      parts = str.match(ISO8601_TIME_REGEX).to_a.pop(5).map(&:to_i)
      if parts.present?
        {hour: parts.first, min: parts.second, sec: parts.third, usec: parts.fourth, utc: true}
      end
    end

    def extract_hour_minute_second_parts(str)
      # match array returns ["12:35:20 AM", "12", "35", "20", "AM"]
      parts = str.match(HOUR_MINUTE_SECOND_REGEX).to_a.pop(4)
      if parts.present?
        {hour: make_hour(parts.first.to_i, parts.fourth), min: parts.second.to_i, sec: parts.third.to_i}
      end
    end

    def extract_hour_minute_parts(str)
      # match array returns ["12:35 AM", "12", "35", "AM"]
      parts = str.match(HOUR_MINUTE_REGEX).to_a.pop(3)
      if parts.present?
        {hour: make_hour(parts.first.to_i, parts.third), min: parts.second.to_i}
      end
    end

    # Convert 2 digit years into 4
    def make_year(year)
      return year if year.to_s.size > 2

      start_year = Flexitime.configuration.time_class.now.year - Flexitime.configuration.ambiguous_year_future_bias
      century = (start_year / 100) * 100
      full_year = century + year
      full_year < start_year ? full_year + 100 : full_year
    end

    # Convert hour depending on presence of am/pm
    def make_hour(hour, meridiem)
      meridiem.to_s.downcase == "pm" ? hour + 12 : hour
    end

    # Validate the day & month parts as Time#local accepts some invalid values
    # such as Time.local(2021,2,30) returning "2021-03-02"
    def valid_date_parts?(parts)
      parts[:month] >= 1 && parts[:month] <= 12 && parts[:day] >= 1 &&
        parts[:day] <= Time.days_in_month(parts[:month], parts[:year])
    end

    # Create a Time object using only those parts required for the configuration precision
    def create_time_from_parts(parts)
      time = Flexitime.configuration.time_class.local(*local_args_for_precision(parts))
      parts[:utc] ? (time + time.utc_offset) : time
    rescue
    end

    # Returns the date/time parts required for the configuration precision
    def local_args_for_precision(parts)
      keys = [:year, :month, :day, :hour, :min, :sec, :usec]
      index = keys.index(Flexitime.configuration.precision)
      keys[0..index].map { |key| parts[key] }
    end

    # Parse the string using the time class and set the configuration precision
    def time_class_parse(str)
      time = Flexitime.configuration.time_class.parse(str)
      set_precision(time)
    rescue
    end

    # Set the precision, first checking if this is necessary
    # to avoid the overhead of calling the change method
    def set_precision(time)
      index = PRECISIONS.index(Flexitime.configuration.precision)
      dismiss_part = PRECISIONS[index + 1]
      excess = PRECISIONS[(index + 1)..-1].sum { |key| time.send(key) }
      excess > 0 ? time.change(dismiss_part => 0) : time
    end
  end
end
