# Flexitime

Flexitime is a Ruby date/time string parser with the intended purpose of converting a string value received from a UI or API into a Time object. It offers the flexibility of deciphering date/time strings in the most common formats with the ability to self-determine the expected order of the date parts when using [rails-i18n](https://github.com/svenfuchs/rails-i18n) or set this via a configuration option; configure the parser to return Time objects either in the system local time or for a specified [time zone](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html); and set a desired precision for the Time object.

The gem was born of the need to parse date, datetime & time strings in a multi-user environment supporting different locales and time zones. Depending upon the user's locale the UI would return date/time strings in different formats and in different orders (day/month/year or month/day/year). This variation in the ordering of the day and month parts proved to be the main catalyst to finding or creating a date/time parser. The resultant Time object needed to be created in the user's time zone and additionally the system stored times only to a minute precision. Flexitime was created to provide a simple yet flexible parser to meet these needs.

![Build Status](https://github.com/CircleSD/flexitime/actions/workflows/main.yml/badge.svg?branch=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'flexitime'
```

And then execute:

```ruby
bundle install
```

Or install it yourself as:

```ruby
gem install flexitime
```

## Usage

The Flexitime `parse` method accepts a string argument or an object that implements the `to_str` method to denote that it behaves like a string. When the string is recognised as a valid date, datetime or time it returns a Time object otherwise it returns `nil` if any of the date/time parts are invalid or the string does not match a recognised format.

```ruby
Flexitime.parse("23/08/2021")       # => 2021-08-23 00:00:00 +0100
Flexitime.parse("23/08/2021 08:00") # => 2021-08-23 08:00:00 +0100
Flexitime.parse("08:00")            # => 2021-11-21 08:00:00 +0000
```

```ruby
Flexitime.parse("31/02/2021 08:00") # => nil
Flexitime.parse("computer says no") # => nil
```

## Formats

Flexitime uses regular expressions to match the string to the most common date & time formats and uses the matched parts to create a Time object.

Dates separated by either forward slashes `/` hyphens `-` or periods `.`; with 1 or 2 digit days and months; with 2 or 4 digit years; and with day/month or year first (always a 4 digit year).

```text
01/08/2021
01-08-2021
01.08.2021
1/8/2021
1-8-2021
1.8.2021
01/08/21
01-08-21
01.08.21
1/8/21
1-8-21
1.8.21
2021/08/01
2021-08-01
2021.08.01
2021/8/1
2021-8-1
2021.8.1
```

Times with hours, minutes & seconds separated by colons `:`; with hours & minutes separated by either colons `:` or periods `.`; with 1 or 2 digit hours; and with case-insensitive AM or PM.

```text
08:15:30
08:15
08.15
8:15:30
8.15
08:15:30 PM
08:15 am
```

Also times in the ISO 8601 Zulu format with between 1 and 6 digit milliseconds

```text
2021-08-01T08:15:30.144515Z
```

If the string does not match any of the regular expressions then Flexitime will attempt to parse the string using the time class, so you lose nothing from using Flexitime and it will still return a Time object for a string containing, for example, an offset or words.

```ruby
Flexitime.parse("2021-01-02T09:00:00+02:00")  # => 2021-01-02 09:00:00 +0200
Flexitime.parse("2nd January 2021")           # => 2021-01-02 00:00:00 +0000
```

## Configuration

### Time Class

The Flexitime `time_class` configuration option is used to create Time objects and defaults to the `Time` class which will use the system local time zone. The `time_class` can be set to an ActiveSupport [TimeZone](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html) to create Time objects using the specified time zone.

```ruby
Time.zone = "Europe/London"
Flexitime.time_class = Time.zone
Flexitime.parse("01/06/2021 17:00") # => Tue, 01 Jun 2021 17:00:00.000000000 BST +01:00
```

### First Date Part

The Flexitime `first_date_part` configuration option is used to denote the first part of the date within the string, either `:day` or `:month`. When using the [rails-I18n gem](https://github.com/svenfuchs/rails-i18n) if the first element of the "date.order" translation is :day or :month that will be used. Alternatively the option can be set manually or finally the default of `:day` will be used.

```ruby
I18n.locale = :"en-GB"
I18n.t("date.order")          # => [:day, :month, :year]
Flexitime.parse("01/06/2021") # => 2021-06-01 00:00:00 +0100

I18n.locale = :"en-US"
I18n.t("date.order")          # => [:month, :day, :year]
Flexitime.parse("01/06/2021") # => 2021-01-06 00:00:00 +0100
```

```ruby
Flexitime.first_date_part = :day
Flexitime.parse("01/06/2021") # => 2021-06-01 00:00:00 +0100

Flexitime.first_date_part = :month
Flexitime.parse("01/06/2021") # => 2021-01-06 00:00:00 +0100
```

Regardless of the `first_date_part` value, Flexitime will always attempt to parse a string starting with a 4 digit year, deciphering the format as year/month/day.

```ruby
Flexitime.parse("2021-11-12 08:15") # => 2021-11-12 08:15:00 +0000
```

### Precision

The Flexitime `precision` configuration option denotes the desired precision for the returned Time objects. This defaults to minute (`:min`) meaning that the Time object will be returned without seconds. The accepted values are `:day`, `:hour`, `:min`, `:sec` or `:usec`

```ruby
Flexitime.precision = :day
Flexitime.parse("2022-12-01T18:30:45.036711Z")  # => 2022-12-01 00:00:00 +0000
Flexitime.precision = :hour
Flexitime.parse("2022-12-01T18:30:45.036711Z")  # => 2022-12-01 18:00:00 +0000
Flexitime.precision = :min
Flexitime.parse("2022-12-01T18:30:45.036711Z")  # => 2022-12-01 18:30:00 +0000
Flexitime.precision = :sec
Flexitime.parse("2022-12-01T18:30:45.036711Z")  # => 2022-12-01 18:30:45 +0000
Flexitime.precision = :usec
Flexitime.parse("2022-12-01T18:30:45.036711Z")  # => 2022-12-01 18:30:45.036711 +0000
```

### Ambiguous Year Future Bias

The Flexitime `ambiguous_year_future_bias` configuration option is used to determine the century when parsing a string containing a 2 digit year and defaults to 50.

With a bias of 50, when the current year is 2020 the Time object's year is set from within a range of >= 1970 and <= 2069

With a bias of 20, when the current year is 2020 the Time object's year is set from within a range of >= 2000 and <= 2099

```ruby
Flexitime.parse("01/08/00").year # => 2000
Flexitime.parse("01/08/69").year # => 2069
Flexitime.parse("01/08/70").year # => 1970
Flexitime.parse("01/08/99").year # => 1999
```

### Thread Safety

The Flexitime `configuration` instance is stored in the currently executing thread as a thread-local variable in order to avoid conflicts with concurrent requests and make the variable threadsafe.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

After making changes run `rake spec` to run the tests and `bundle exec appraisal rspec` to run the tests against different versions of activesupport; and run `bundle exec standardrb` to check the style of files.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/CircleSD/flexitime). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/CircleSD/flexitime/blob/main/CODE_OF_CONDUCT.md).

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Credits

Tom Preston-Werner and [Chronic](https://github.com/mojombo/chronic) which was our previous go-to parser of choice but is unfortunately no longer maintained and performs natural language parsing that we do not require. It was a useful reference in particular for the `time_class` and `ambiguous_year_future_bias` configuration options.

Adam Meehan and [Timeliness](https://github.com/adzap/timeliness) which was a close match for our needs but proved to be too strict in its accepted formats particulary as we wanted to cater for a variety of date separators for both day/month/year and month/day/year date ordering. The gem provided some very useful inspiration in regards to code structure with forwarding for the configuration class and testing thread safety.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Flexitime project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/CircleSD/flexitime/blob/main/CODE_OF_CONDUCT.md).
