# frozen_string_literal: true

RSpec.describe Flexitime do
  before do
    Thread.current["Flexitime.configuration"] = nil
    Time.zone = "UTC"
    I18n.locale = :en
  end

  it "has a version number" do
    expect(Flexitime::VERSION).not_to be nil
  end

  describe ".configuration" do
    it "returns default configuration values" do
      expect(Flexitime.configuration.first_date_part).to eq(:day)
      expect(Flexitime.configuration.precision).to eq(:min)
      expect(Flexitime.configuration.ambiguous_year_future_bias).to eq(50)
    end

    describe "#first_date_part" do
      it "returns the default first date part" do
        expect(Flexitime.configuration.instance_variable_get(:@first_date_part)).to be_nil
        expect(Flexitime.configuration.first_date_part).to eq(:day)
      end

      it "sets the first date part to :day" do
        Flexitime.configuration.first_date_part = :day
        expect(Flexitime.configuration.instance_variable_get(:@first_date_part)).to eq(:day)
        expect(Flexitime.configuration.first_date_part).to eq(:day)
      end

      it "sets the first date part to :month" do
        Flexitime.configuration.first_date_part = :month
        expect(Flexitime.configuration.instance_variable_get(:@first_date_part)).to eq(:month)
        expect(Flexitime.configuration.first_date_part).to eq(:month)
      end

      it "converts the first date part to a symbol" do
        Flexitime.configuration.first_date_part = "month"
        expect(Flexitime.configuration.first_date_part).to eq(:month)
      end

      it "raises an error when the first date part is not :day or :month" do
        expect { Flexitime.configuration.first_date_part = "boom!" }.to raise_error(ArgumentError)
        expect { Flexitime.configuration.first_date_part = "" }.to raise_error(ArgumentError)
        expect { Flexitime.configuration.first_date_part = nil }.to raise_error(ArgumentError)
        expect { Flexitime.configuration.first_date_part = :year }.to raise_error(ArgumentError)
        expect { Flexitime.configuration.first_date_part = [:day, :month, :year] }.to raise_error(ArgumentError)
      end

      context "when the rails-i18n date order translations exist" do
        before do
          # add translations from rails-i18n
          I18n.backend.store_translations :"en-GB", date: {order: [:day, :month, :year]}
          I18n.backend.store_translations :"en-US", date: {order: [:month, :day, :year]}
          I18n.backend.store_translations :"en-IE", date: {order: %w[month day year]}
        end

        after do
          I18n.backend.reload!
        end

        it "returns the default first date part for the en locale of :year, :month and :day" do
          I18n.locale = :en
          expect(I18n.t("date.order")).to eq(["year", "month", "day"])
          expect(Flexitime.configuration.instance_variable_get(:@first_date_part)).to be_nil
          expect(Flexitime.configuration.first_date_part).to eq(:day)
        end

        it "returns the en-GB locale first date part of :day" do
          I18n.locale = :"en-GB"
          expect(I18n.t("date.order")).to eq([:day, :month, :year])
          expect(Flexitime.configuration.instance_variable_get(:@first_date_part)).to be_nil
          expect(Flexitime.configuration.first_date_part).to eq(:day)
        end

        it "returns the en-US locale first date part of :month" do
          I18n.locale = :"en-US"
          expect(I18n.t("date.order")).to eq([:month, :day, :year])
          expect(Flexitime.configuration.instance_variable_get(:@first_date_part)).to be_nil
          expect(Flexitime.configuration.first_date_part).to eq(:month)
        end

        it "returns the first date part as a symbol if the translation returns a string" do
          I18n.locale = :"en-IE"
          expect(I18n.t("date.order")).to eq(%w[month day year])
          expect(Flexitime.configuration.instance_variable_get(:@first_date_part)).to be_nil
          expect(Flexitime.configuration.first_date_part).to eq(:month)
        end

        it "returns the default first date part when the translation is missing" do
          I18n.locale = :nl
          expect(I18n.t("date.order")).to eq("translation missing: nl.date.order")
          expect(Flexitime.configuration.instance_variable_get(:@first_date_part)).to be_nil
          expect(Flexitime.configuration.first_date_part).to eq(:day)
        end

        it "returns the first date part attribute value" do
          I18n.locale = :"en-GB"
          expect(I18n.t("date.order")).to eq([:day, :month, :year])
          Flexitime.configuration.first_date_part = :month
          expect(Flexitime.configuration.instance_variable_get(:@first_date_part)).to eq(:month)
          expect(Flexitime.configuration.first_date_part).to eq(:month)
        end
      end
    end

    describe "#precision" do
      it "returns the default precision" do
        expect(Flexitime.configuration.precision).to eq(:min)
      end

      Flexitime::PRECISIONS.each do |precision|
        it "sets the precision to :#{precision}" do
          Flexitime.configuration.precision = precision.to_sym
          expect(Flexitime.configuration.precision).to eq(precision.to_sym)
        end
      end

      it "converts the precision to a symbol" do
        Flexitime.configuration.precision = "sec"
        expect(Flexitime.configuration.precision).to eq(:sec)
      end

      it "raises an error when the precision is invalid" do
        expect { Flexitime.configuration.precision = "boom!" }.to raise_error(ArgumentError)
        expect { Flexitime.configuration.precision = :minute }.to raise_error(ArgumentError)
        expect { Flexitime.configuration.precision = "" }.to raise_error(ArgumentError)
        expect { Flexitime.configuration.precision = nil }.to raise_error(ArgumentError)
        expect { Flexitime.configuration.precision = [:minute] }.to raise_error(ArgumentError)
      end
    end

    describe "#ambiguous_year_future_bias" do
      it "returns the default ambiguous year future bias" do
        expect(Flexitime.configuration.ambiguous_year_future_bias).to eq(50)
      end

      it "sets the ambiguous year future bias" do
        Flexitime.configuration.ambiguous_year_future_bias = 25
        expect(Flexitime.configuration.ambiguous_year_future_bias).to eq(25)
      end
    end

    it "is thread specific as it is stored in a thread-local variable" do
      str = "02/06/2021"
      threads = {
        day: Thread.new {
          sleep(0.005)
          Flexitime.parse(str)
        },
        month: Thread.new {
          sleep(0.001)
          Flexitime.first_date_part = :month
          Flexitime.parse(str)
        }
      }
      threads.values.each(&:join)

      expect(threads[:day].value).to eq(Time.zone.local(2021, 6, 2))
      expect(threads[:month].value).to eq(Time.zone.local(2021, 2, 6))
    end
  end

  describe ".first_date_part" do
    it "delegates to the configuration method" do
      expect(Flexitime.first_date_part).to eq(:day)
      Flexitime.first_date_part = :month
      expect(Flexitime.first_date_part).to eq(:month)
      expect(Flexitime.configuration.first_date_part).to eq(:month)
    end
  end

  describe ".precision" do
    it "delegates to the configuration method" do
      expect(Flexitime.precision).to eq(:min)
      Flexitime.precision = :sec
      expect(Flexitime.precision).to eq(:sec)
      expect(Flexitime.precision).to eq(:sec)
    end
  end

  describe ".ambiguous_year_future_bias" do
    it "delegates to the configuration method" do
      expect(Flexitime.ambiguous_year_future_bias).to eq(50)
      Flexitime.ambiguous_year_future_bias = 55
      expect(Flexitime.ambiguous_year_future_bias).to eq(55)
      expect(Flexitime.ambiguous_year_future_bias).to eq(55)
    end
  end

  describe ".parse" do
    it "returns nil if the string argument is blank" do
      expect(Flexitime.parse("")).to be_nil
    end

    it "returns nil if the string argument is blank with whitespace" do
      expect(Flexitime.parse(" ")).to be_nil
    end

    it "returns nil if the argument is nil" do
      expect(Flexitime.parse(nil)).to be_nil
    end

    it "returns nil if the argument is a number" do
      expect(Flexitime.parse(1)).to be_nil
    end

    it "returns nil if the argument is a Date" do
      expect(Flexitime.parse(Date.current)).to be_nil
    end

    it "returns nil if the argument is a DateTime" do
      expect(Flexitime.parse(DateTime.current)).to be_nil
    end

    it "returns nil if the argument is a Time" do
      expect(Flexitime.parse(Time.now)).to be_nil
    end

    it "returns nil if the argument is a TimeWithZone" do
      expect(Flexitime.parse(Time.zone.now)).to be_nil
    end

    it "returns nil if the string argument is not a recognised format" do
      expect(Flexitime.parse("a")).to be_nil
    end

    it "returns nil if the string argument includes an invalid date and time" do
      expect(Flexitime.parse("2021-13-32 30:99:99")).to be_nil
    end

    it "returns nil if the string argument includes an invalid day of 00" do
      expect(Flexitime.parse("2021-12-00")).to be_nil
    end

    it "returns nil if the string argument includes an invalid day of 31" do
      expect(Flexitime.parse("2021-09-31")).to be_nil
    end

    it "returns nil if the string argument includes an invalid month of 00" do
      expect(Flexitime.parse("2021-00-01")).to be_nil
    end

    it "returns nil if the string argument includes an invalid month of 13" do
      expect(Flexitime.parse("2021-13-01")).to be_nil
    end

    it "returns nil if the string argument includes an invalid year of 00" do
      expect(Flexitime.parse("00-01-01")).to be_nil
    end

    it "returns nil if the string argument includes an invalid hour of 25" do
      expect(Flexitime.parse("2021-09-09 25:00")).to be_nil
    end

    it "returns nil if the string argument includes an invalid minute of 61" do
      expect(Flexitime.parse("2021-09-09 12:61")).to be_nil
    end

    it "returns nil if the string argument includes an invalid second of 61" do
      Flexitime.configuration.precision = :sec
      expect(Flexitime.parse("2021-09-09 12:30:61")).to be_nil
    end

    it "parses a string using Time.zone" do
      flexitime = Flexitime.parse("23/08/2021 08:15")
      expect(flexitime).to eq(Time.zone.parse("23/08/2021 08:15"))
      expect(flexitime.utc_offset).to eq(0)
      Time.zone = "Europe/London"
      flexitime = Flexitime.parse("23/08/2021 08:15")
      expect(flexitime).to eq(Time.zone.parse("23/08/2021 08:15"))
      expect(flexitime.utc_offset).to eq(3600)
      Time.zone = "Australia/Sydney"
      flexitime = Flexitime.parse("23/08/2021 08:15")
      expect(flexitime).to eq(Time.zone.parse("23/08/2021 08:15"))
      expect(flexitime.utc_offset).to eq(36000)
      Time.zone = "America/New_York"
      flexitime = Flexitime.parse("23/08/2021 08:15")
      expect(flexitime).to eq(Time.zone.parse("23/08/2021 08:15"))
      expect(flexitime.utc_offset).to eq(-14400)
    end

    context "when Time.zone is nil" do
      it "parses a string using a Time.zone of 'UTC'" do
        Time.zone = nil
        flexitime = Flexitime.parse("23/08/2021 08:15")
        expect(flexitime).to eq(Time.zone.parse("23/08/2021 08:15"))
        expect(Time.zone.name).to eq("UTC")
      end
    end

    context "with a date string in day/month/year order" do
      it "returns a time for a string separated by forward slashes" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("12/11/2021")
        time = Time.zone.local(2021, 11, 12)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a string separated by hyphens" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("12-11-2021")
        time = Time.zone.local(2021, 11, 12)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a string separated by periods" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("12.11.2021")
        time = Time.zone.local(2021, 11, 12)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a string including single digit day and month" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("8/2/2021")
        time = Time.zone.local(2021, 2, 8)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a string including 2 digit year" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("08/02/21")
        time = Time.zone.local(2021, 2, 8)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a string including single digit day & month and 2 digit year" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("8/2/21")
        time = Time.zone.local(2021, 2, 8)
        expect(flexitime).to eq(time)
      end
    end

    context "with a date string in year/month/day order" do
      it "returns a time for a string separated by forward slashes" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("2021/11/12")
        time = Time.zone.local(2021, 11, 12)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a string separated by hyphens" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("2021-11-12")
        time = Time.zone.local(2021, 11, 12)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a string separated by periods" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("2021.11.12")
        time = Time.zone.local(2021, 11, 12)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a string including single digit day and month" do
        expect(Flexitime).to receive(:create_time_from_parts).and_call_original
        flexitime = Flexitime.parse("2021/2/8")
        time = Time.zone.local(2021, 2, 8)
        expect(flexitime).to eq(time)
      end
    end

    context "with a datetime string" do
      context "including hour, minute and second separated by colons" do
        it "returns a time" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021/11/12 08:15:30")
          time = Time.zone.local(2021, 11, 12, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase AM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021/11/12 08:15:30 AM")
          time = Time.zone.local(2021, 11, 12, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021/11/12 08:15:30 PM")
          time = Time.zone.local(2021, 11, 12, 20, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase am" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021/11/12 08:15:30 am")
          time = Time.zone.local(2021, 11, 12, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase pm" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021/11/12 08:15:30 pm")
          time = Time.zone.local(2021, 11, 12, 20, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including AM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021/11/12 08:15:30AM")
          time = Time.zone.local(2021, 11, 12, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including PM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021/11/12 08:15:30PM")
          time = Time.zone.local(2021, 11, 12, 20, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("12/11/2021 8:15:30")
          time = Time.zone.local(2021, 11, 12, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour and PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("12/11/2021 8:15:30 PM")
          time = Time.zone.local(2021, 11, 12, 20, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string with the time surrounded by white space" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("12/11/2021  08:15:30  ")
          time = Time.zone.local(2021, 11, 12, 8, 15, 30)
          expect(flexitime).to eq(time)
        end
      end

      context "including hour and minute separated by a colon" do
        it "returns a time" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021/11/12 08:15")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase AM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08:15 AM")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08:15 PM")
          time = Time.zone.local(2021, 11, 12, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase am" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08:15am")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase pm" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08:15pm")
          time = Time.zone.local(2021, 11, 12, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including AM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08:15AM")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including PM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08:15PM")
          time = Time.zone.local(2021, 11, 12, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("12/11/2021 8:15")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour and PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("12/11/2021 8:15 PM")
          time = Time.zone.local(2021, 11, 12, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string with the time surrounded by white space" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("12/11/2021  08:15  ")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end
      end

      context "including hour and minute separated by a period" do
        it "returns a time" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021/11/12 08.15")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase AM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08.15 AM")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08.15 PM")
          time = Time.zone.local(2021, 11, 12, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase am" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08.15am")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase pm" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08.15pm")
          time = Time.zone.local(2021, 11, 12, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including AM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08.15AM")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including PM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021/11/12 08.15PM")
          time = Time.zone.local(2021, 11, 12, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("12/11/2021 8.15")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour and PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("12/11/2021 8.15 PM")
          time = Time.zone.local(2021, 11, 12, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string with the time surrounded by white space" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("12/11/2021  08.15  ")
          time = Time.zone.local(2021, 11, 12, 8, 15)
          expect(flexitime).to eq(time)
        end
      end

      context "including an ISO 8601 formatted Zulu time" do
        it "returns a time for a string including 6 digit milliseconds" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :usec
          flexitime = Flexitime.parse("2021-11-12T08:15:30.144515Z")
          time = Time.utc(2021, 11, 12, 8, 15, 30, 144515).in_time_zone
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including 5 digit milliseconds" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :usec
          flexitime = Flexitime.parse("2021-11-12T08:15:30.14451Z")
          time = Time.utc(2021, 11, 12, 8, 15, 30, 14451).in_time_zone
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including 4 digit milliseconds" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :usec
          flexitime = Flexitime.parse("2021-11-12T10:15:30.1445Z")
          time = Time.utc(2021, 11, 12, 10, 15, 30, 1445).in_time_zone
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including 3 digit milliseconds" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :usec
          flexitime = Flexitime.parse("2021-11-12T12:15:30.144Z")
          time = Time.utc(2021, 11, 12, 12, 15, 30, 144).in_time_zone
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including 2 digit milliseconds" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :usec
          flexitime = Flexitime.parse("2021-11-12T14:15:30.14Z")
          time = Time.utc(2021, 11, 12, 14, 15, 30, 14).in_time_zone
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including 1 digit milliseconds" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :usec
          flexitime = Flexitime.parse("2021-11-12T16:15:30.1Z")
          time = Time.utc(2021, 11, 12, 16, 15, 30, 1).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "with a time string" do
      let(:now) { Time.zone.now }

      context "including hour, minute and second separated by colons" do
        it "returns a time" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("08:15:30")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase AM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("08:15:30 AM")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("08:15:30 PM")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase am" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("08:15:30 am")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase pm" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("08:15:30 pm")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including AM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("08:15:30AM")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including PM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("08:15:30PM")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("8:15:30")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour and PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("8:15:30 PM")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15, 30)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string with the time surrounded by white space" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("  08:15:30  ")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15, 30)
          expect(flexitime).to eq(time)
        end
      end

      context "including hour and minute separated by a colon" do
        it "returns a time" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("08:15")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase AM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08:15 AM")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08:15 PM")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase am" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08:15am")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase pm" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08:15pm")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including AM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08:15AM")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including PM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08:15PM")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("8:15")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour and PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("8:15 PM")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string with the time surrounded by white space" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("  08:15  ")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end
      end

      context "including hour and minute separated by a period" do
        it "returns a time" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("08.15")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase AM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08.15 AM")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including uppercase PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08.15 PM")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase am" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08.15am")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including lowercase pm" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08.15pm")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including AM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08.15AM")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including PM without a space separator" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("08.15PM")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("8.15")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string including single digit hour and PM" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("8.15 PM")
          time = Time.zone.local(now.year, now.month, now.day, 20, 15)
          expect(flexitime).to eq(time)
        end

        it "returns a time for a string with the time surrounded by white space" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("  08.15  ")
          time = Time.zone.local(now.year, now.month, now.day, 8, 15)
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when parsing the string using Time.zone" do
      it "returns a time for a datetime string in dB format" do
        expect(Flexitime).to receive(:time_zone_parse).and_call_original
        flexitime = Flexitime.parse("2021-01-02T09:00:00+00:00")
        time = Time.utc(2021, 1, 2, 9).in_time_zone
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with milliseconds" do
        expect(Flexitime).to receive(:time_zone_parse).and_call_original
        flexitime = Flexitime.parse("01/12/2021 18:30:45.036711")
        time = Time.utc(2021, 12, 1, 18, 30).in_time_zone
        expect(flexitime).to eq(time)
      end

      it "returns a time for a date string in wordy format" do
        expect(Flexitime).to receive(:time_zone_parse).and_call_original
        flexitime = Flexitime.parse("2nd January 2021")
        time = Time.zone.local(2021, 1, 2)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with the hour, minute and second separated by periods" do
        # might not be the right time but test proves that with this time format the time_zone_parse is used
        expect(Flexitime).to receive(:time_zone_parse).and_call_original
        Flexitime.configuration.precision = :sec
        flexitime = Flexitime.parse("2021/11/12 08.15.30")
        time = Time.zone.local(2021, 11, 12)
        expect(flexitime).to eq(time)
      end
    end

    context "when Time.zone is set to 'Europe/London'" do
      before do
        Time.zone = "Europe/London"
      end

      it "returns a time for a datetime string in British Summer Time (BST)" do
        flexitime = Flexitime.parse("23/08/2021 08:15")
        time = Time.zone.parse("23/08/2021 08:15")
        expect(flexitime).to eq(time)
        expect(flexitime.hour).to eq(8)
        expect(flexitime.min).to eq(15)
        expect(flexitime.utc_offset).to eq(3600)
      end

      it "returns a time for a datetime string in Greenwich Mean Time (GMT)" do
        flexitime = Flexitime.parse("25/12/2021 08:15")
        time = Time.zone.parse("25/12/2021 08:15")
        expect(flexitime).to eq(time)
        expect(flexitime.hour).to eq(8)
        expect(flexitime.min).to eq(15)
        expect(flexitime.utc_offset).to eq(0)
      end

      it "returns a time for a datetime string on the hour before BST starts" do
        flexitime = Flexitime.parse("28/03/2021 00:00")
        time = Time.zone.parse("28/03/2021 00:00")
        expect(flexitime).to eq(time)
        expect(flexitime.day).to eq(28)
        expect(flexitime.hour).to eq(0)
        expect(flexitime.min).to eq(0)
        expect(flexitime.utc_offset).to eq(0)
      end

      it "returns a time for a datetime on the hour that BST starts" do
        flexitime = Flexitime.parse("28/03/2021 01:00")
        time = Time.zone.parse("28/03/2021 01:00")
        expect(flexitime).to eq(time)
        expect(flexitime.day).to eq(28)
        expect(flexitime.hour).to eq(2)
        expect(flexitime.min).to eq(0)
        expect(flexitime.utc_offset).to eq(3600)
      end

      it "returns a time for a datetime on the hour after BST starts" do
        flexitime = Flexitime.parse("28/03/2021 02:00")
        time = Time.zone.parse("28/03/2021 02:00")
        expect(flexitime).to eq(time)
        expect(flexitime.day).to eq(28)
        expect(flexitime.hour).to eq(2)
        expect(flexitime.min).to eq(0)
        expect(flexitime.utc_offset).to eq(3600)
      end

      it "returns a time for a datetime string on the hour before BST ends" do
        flexitime = Flexitime.parse("31/10/2021 01:00")
        time = Time.zone.parse("31/10/2021 01:00")
        expect(flexitime).to eq(time)
        expect(flexitime.day).to eq(31)
        expect(flexitime.hour).to eq(1)
        expect(flexitime.min).to eq(0)
        expect(flexitime.utc_offset).to eq(3600)
      end

      it "returns a time for a datetime on the hour that BST ends" do
        flexitime = Flexitime.parse("31/10/2021 02:00")
        time = Time.zone.parse("31/10/2021 02:00")
        expect(flexitime).to eq(time)
        expect(flexitime.day).to eq(31)
        expect(flexitime.hour).to eq(2)
        expect(flexitime.min).to eq(0)
        expect(flexitime.utc_offset).to eq(0)
      end

      it "returns a time for a datetime on the hour after BST ends" do
        flexitime = Flexitime.parse("31/10/2021 03:00")
        time = Time.zone.parse("31/10/2021 03:00")
        expect(flexitime).to eq(time)
        expect(flexitime.day).to eq(31)
        expect(flexitime.hour).to eq(3)
        expect(flexitime.min).to eq(0)
        expect(flexitime.utc_offset).to eq(0)
      end

      it "returns a time for an ISO 8601 formatted Zulu datetime string" do
        flexitime = Flexitime.parse("2021-08-01T08:15:30.144515Z")
        time = Time.utc(2021, 8, 1, 8, 15).in_time_zone
        expect(flexitime).to eq(time)
      end
    end

    context "when Time.zone is set to 'Australia/Sydney'" do
      before do
        Time.zone = "Australia/Sydney"
      end

      it "returns a time for a datetime string in Australian Eastern Standard Time (AEST)" do
        flexitime = Flexitime.parse("23/08/2021 08:15")
        time = Time.zone.parse("23/08/2021 08:15")
        expect(flexitime).to eq(time)
        expect(flexitime.hour).to eq(8)
        expect(flexitime.min).to eq(15)
        expect(flexitime.utc_offset).to eq(36000)
      end

      it "returns a time for a datetime string in Australian Eastern Daylight Time (AEDT)" do
        flexitime = Flexitime.parse("25/12/2021 08:15")
        time = Time.zone.parse("25/12/2021 08:15")
        expect(flexitime).to eq(time)
        expect(flexitime.hour).to eq(8)
        expect(flexitime.min).to eq(15)
        expect(flexitime.utc_offset).to eq(39600)
      end

      it "returns a time for an ISO 8601 formatted Zulu datetime string" do
        flexitime = Flexitime.parse("2021-08-01T08:15:30.144515Z")
        time = Time.utc(2021, 8, 1, 8, 15).in_time_zone
        expect(flexitime).to eq(time)
      end
    end

    context "when Time.zone is set to 'America/New_York'" do
      before do
        Time.zone = "America/New_York"
      end

      it "returns a time for a datetime string in Eastern Daylight Time (EDT)" do
        flexitime = Flexitime.parse("23/08/2021 08:15")
        time = Time.zone.parse("23/08/2021 08:15")
        expect(flexitime).to eq(time)
        expect(flexitime.hour).to eq(8)
        expect(flexitime.min).to eq(15)
        expect(flexitime.utc_offset).to eq(-14400)
      end

      it "returns a time for a datetime string in Eastern Standard Time (EST)" do
        flexitime = Flexitime.parse("25/12/2021 08:15")
        time = Time.zone.parse("25/12/2021 08:15")
        expect(flexitime).to eq(time)
        expect(flexitime.hour).to eq(8)
        expect(flexitime.min).to eq(15)
        expect(flexitime.utc_offset).to eq(-18000)
      end

      it "returns a time for an ISO 8601 formatted Zulu datetime string" do
        flexitime = Flexitime.parse("2021-08-01T08:15:30.144515Z")
        time = Time.utc(2021, 8, 1, 8, 15).in_time_zone
        expect(flexitime).to eq(time)
      end
    end

    context "when Time.zone is set to 'UTC'" do
      before do
        Time.zone = "UTC"
      end

      it "returns a time for a datetime string" do
        flexitime = Flexitime.parse("23/08/2021 08:15")
        time = Time.zone.parse("23/08/2021 08:15")
        expect(flexitime).to eq(time)
        expect(flexitime.hour).to eq(8)
        expect(flexitime.min).to eq(15)
        expect(flexitime.utc_offset).to eq(0)
      end

      it "returns a time for a datetime string" do
        flexitime = Flexitime.parse("25/12/2021 08:15")
        time = Time.zone.parse("25/12/2021 08:15")
        expect(flexitime).to eq(time)
        expect(flexitime.hour).to eq(8)
        expect(flexitime.min).to eq(15)
        expect(flexitime.utc_offset).to eq(0)
      end

      it "returns a time for an ISO 8601 formatted Zulu datetime string" do
        flexitime = Flexitime.parse("2021-08-01T08:15:30.144515Z")
        time = Time.utc(2021, 8, 1, 8, 15).in_time_zone
        expect(flexitime).to eq(time)
      end
    end

    context "when the configuration first date part is :day" do
      before do
        Flexitime.configuration.first_date_part = :day
      end

      it "returns a time for a date string with the date set based on the first date part" do
        flexitime = Flexitime.parse("01/08/2021")
        time = Time.zone.local(2021, 8, 1)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with the date set based on the first date part" do
        flexitime = Flexitime.parse("01/08/2021 08:15")
        time = Time.zone.local(2021, 8, 1, 8, 15)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a date string with a 2 digit year based on the first date part" do
        flexitime = Flexitime.parse("01/08/21")
        time = Time.zone.local(2021, 8, 1)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with a 2 digit year based on the first date part" do
        flexitime = Flexitime.parse("01/08/21 08:15")
        time = Time.zone.local(2021, 8, 1, 8, 15)
        expect(flexitime).to eq(time)
      end

      it "returns a time for an ISO 8601 formatted datetime string" do
        flexitime = Flexitime.parse("2021-08-01T08:15:30.144515Z")
        time = Time.utc(2021, 8, 1, 8, 15).in_time_zone
        expect(flexitime).to eq(time)
      end
    end

    context "when the configuration first date part is :month" do
      before do
        Flexitime.configuration.first_date_part = :month
      end

      it "returns a time for a date string with the date set based on the first date part" do
        flexitime = Flexitime.parse("01/08/2021")
        time = Time.zone.local(2021, 1, 8)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with the date set based on the first date part" do
        flexitime = Flexitime.parse("01/08/2021 08:15")
        time = Time.zone.local(2021, 1, 8, 8, 15)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a date string with a 2 digit year based on the first date part" do
        flexitime = Flexitime.parse("01/08/21")
        time = Time.zone.local(2021, 1, 8)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with a 2 digit year based on the first date part" do
        flexitime = Flexitime.parse("01/08/21 08:15")
        time = Time.zone.local(2021, 1, 8, 8, 15)
        expect(flexitime).to eq(time)
      end

      it "returns a time for an ISO 8601 formatted datetime string" do
        flexitime = Flexitime.parse("2021-08-01T08:15:30.144515Z")
        time = Time.utc(2021, 8, 1, 8, 15).in_time_zone
        expect(flexitime).to eq(time)
      end
    end

    context "when using the argument first date part" do
      it "parses the string and retains the configuration first date part setting" do
        expect(Flexitime.configuration.first_date_part).to eq(:day)
        flexitime = Flexitime.parse("01/08/2021", first_date_part: :month)
        time = Time.zone.local(2021, 1, 8)
        expect(flexitime).to eq(time)
        expect(Flexitime.configuration.first_date_part).to eq(:day)
      end

      it "raises an error when the first date part is invalid" do
        expect { Flexitime.parse("01/08/2021", first_date_part: :year) }.to raise_error(ArgumentError)
      end
    end

    context "when the argument first date part is :day" do
      before do
        Flexitime.configuration.first_date_part = :month
      end

      it "returns a time for a date string with the date set based on the first date part" do
        flexitime = Flexitime.parse("01/08/2021", first_date_part: :day)
        time = Time.zone.local(2021, 8, 1)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with the date set based on the first date part" do
        flexitime = Flexitime.parse("01/08/2021 08:15", first_date_part: :day)
        time = Time.zone.local(2021, 8, 1, 8, 15)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a date string with a 2 digit year based on the first date part" do
        flexitime = Flexitime.parse("01/08/21", first_date_part: :day)
        time = Time.zone.local(2021, 8, 1)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with a 2 digit year based on the first date part" do
        flexitime = Flexitime.parse("01/08/21 08:15", first_date_part: :day)
        time = Time.zone.local(2021, 8, 1, 8, 15)
        expect(flexitime).to eq(time)
      end

      it "returns a time for an ISO 8601 formatted datetime string" do
        flexitime = Flexitime.parse("2021-08-01T08:15:30.144515Z", first_date_part: :day)
        time = Time.utc(2021, 8, 1, 8, 15).in_time_zone
        expect(flexitime).to eq(time)
      end
    end

    context "when the argument first date part is :month" do
      before do
        Flexitime.configuration.first_date_part = :day
      end

      it "returns a time for a date string with the date set based on the first date part" do
        flexitime = Flexitime.parse("01/08/2021", first_date_part: :month)
        time = Time.zone.local(2021, 1, 8)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with the date set based on the first date part" do
        flexitime = Flexitime.parse("01/08/2021 08:15", first_date_part: :month)
        time = Time.zone.local(2021, 1, 8, 8, 15)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a date string with a 2 digit year based on the first date part" do
        flexitime = Flexitime.parse("01/08/21", first_date_part: :month)
        time = Time.zone.local(2021, 1, 8)
        expect(flexitime).to eq(time)
      end

      it "returns a time for a datetime string with a 2 digit year based on the first date part" do
        flexitime = Flexitime.parse("01/08/21 08:15", first_date_part: :month)
        time = Time.zone.local(2021, 1, 8, 8, 15)
        expect(flexitime).to eq(time)
      end

      it "returns a time for an ISO 8601 formatted datetime string" do
        flexitime = Flexitime.parse("2021-08-01T08:15:30.144515Z", first_date_part: :month)
        time = Time.utc(2021, 8, 1, 8, 15).in_time_zone
        expect(flexitime).to eq(time)
      end
    end

    context "when using the default configuration precision of :min" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :min" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021-08-23 12:35:20")
          time = Time.zone.local(2021, 8, 23, 12, 35)
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :min" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00")
          time = Time.utc(2021, 8, 23, 12, 35).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the configuration precision of :usec" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :usec" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :usec
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314Z")
          time = Time.utc(2021, 8, 23, 12, 35, 20, 533314).in_time_zone
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :usec" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          Flexitime.configuration.precision = :usec
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00")
          time = Time.utc(2021, 8, 23, 12, 35, 20, 533314).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the configuration precision of :sec" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :sec" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314Z")
          time = Time.utc(2021, 8, 23, 12, 35, 20).in_time_zone
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :sec" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          Flexitime.configuration.precision = :sec
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00")
          time = Time.utc(2021, 8, 23, 12, 35, 20).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the configuration precision of :min" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :min" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :min
          flexitime = Flexitime.parse("2021-08-23 12:35:20")
          time = Time.zone.local(2021, 8, 23, 12, 35)
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :min" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          Flexitime.configuration.precision = :min
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00")
          time = Time.utc(2021, 8, 23, 12, 35).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the configuration precision of :hour" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :hour" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :hour
          flexitime = Flexitime.parse("2021-08-23 12:35:20")
          time = Time.zone.local(2021, 8, 23, 12)
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :hour" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          Flexitime.configuration.precision = :hour
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00")
          time = Time.utc(2021, 8, 23, 12).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the configuration precision of :day" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :day" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          Flexitime.configuration.precision = :day
          flexitime = Flexitime.parse("2021-08-23 12:35:20")
          time = Time.zone.local(2021, 8, 23)
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :day" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          Flexitime.configuration.precision = :day
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00")
          time = Time.utc(2021, 8, 23).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the argument precision" do
      it "parses the string and retains the configuration precision setting" do
        expect(Flexitime.configuration.precision).to eq(:min)
        flexitime = Flexitime.parse("2021-08-23T12:35:20.533314Z", precision: :sec)
        time = Time.utc(2021, 8, 23, 12, 35, 20).in_time_zone
        expect(flexitime).to eq(time)
        expect(Flexitime.configuration.precision).to eq(:min)
      end

      it "raises an error when the precision is invalid" do
        expect { Flexitime.parse("01/08/2021", precision: :minute) }.to raise_error(ArgumentError)
      end
    end

    context "when using the argument precision of :usec" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :usec" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314Z", precision: :usec)
          time = Time.utc(2021, 8, 23, 12, 35, 20, 533314).in_time_zone
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :usec" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00", precision: :usec)
          time = Time.utc(2021, 8, 23, 12, 35, 20, 533314).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the argument precision of :sec" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :sec" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314Z", precision: :sec)
          time = Time.utc(2021, 8, 23, 12, 35, 20).in_time_zone
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :sec" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00", precision: :sec)
          time = Time.utc(2021, 8, 23, 12, 35, 20).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the argument precision of :min" do
      before do
        Flexitime.configuration.precision = :sec
      end

      context "when parsing the string using regex" do
        it "returns a time with a precision of :min" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021-08-23 12:35:20", precision: :min)
          time = Time.zone.local(2021, 8, 23, 12, 35)
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :min" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00", precision: :min)
          time = Time.utc(2021, 8, 23, 12, 35).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the argument precision of :hour" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :hour" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021-08-23 12:35:20", precision: :hour)
          time = Time.zone.local(2021, 8, 23, 12)
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :hour" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00", precision: :hour)
          time = Time.utc(2021, 8, 23, 12).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the argument precision of :day" do
      context "when parsing the string using regex" do
        it "returns a time with a precision of :day" do
          expect(Flexitime).to receive(:create_time_from_parts).and_call_original
          flexitime = Flexitime.parse("2021-08-23 12:35:20", precision: :day)
          time = Time.zone.local(2021, 8, 23)
          expect(flexitime).to eq(time)
        end
      end

      context "when parsing the string using Time.zone" do
        it "returns a time with a precision of :day" do
          expect(Flexitime).to receive(:time_zone_parse).and_call_original
          flexitime = Flexitime.parse("2021-08-23T12:35:20.533314+00:00", precision: :day)
          time = Time.utc(2021, 8, 23).in_time_zone
          expect(flexitime).to eq(time)
        end
      end
    end

    context "when using the first date part and precision arguments" do
      it "returns a time using the first date part and precision" do
        Flexitime.configuration.precision = :sec
        flexitime = Flexitime.parse("01/08/2021 08:15:30", first_date_part: :day, precision: :min)
        time = Time.zone.local(2021, 8, 1, 8, 15)
        expect(flexitime).to eq(time)
      end
    end

    context "when the string contain a 2 digit year" do
      it "returns a time for a date string with the year set using the ambiguous year future bias of 10" do
        allow(Time.zone).to receive(:now).and_return(Time.zone.local(2020, 1, 1))
        Flexitime.configuration.ambiguous_year_future_bias = 10
        expect(Flexitime.parse("01/08/00").year).to eq(2100)
        expect(Flexitime.parse("01/08/09").year).to eq(2109)
        expect(Flexitime.parse("01/08/10").year).to eq(2010)
        expect(Flexitime.parse("01/08/99").year).to eq(2099)
      end

      it "returns a time for a date string with the year set using the ambiguous year future bias of 30" do
        allow(Time.zone).to receive(:now).and_return(Time.zone.local(2020, 1, 1))
        Flexitime.configuration.ambiguous_year_future_bias = 30
        expect(Flexitime.parse("01/08/00").year).to eq(2000)
        expect(Flexitime.parse("01/08/89").year).to eq(2089)
        expect(Flexitime.parse("01/08/90").year).to eq(1990)
        expect(Flexitime.parse("01/08/99").year).to eq(1999)
      end

      it "returns a time for a date string with the year set using the default ambiguous year future bias of 50" do
        allow(Time.zone).to receive(:now).and_return(Time.zone.local(2020, 1, 1))
        expect(Flexitime.parse("01/08/00").year).to eq(2000)
        expect(Flexitime.parse("01/08/69").year).to eq(2069)
        expect(Flexitime.parse("01/08/70").year).to eq(1970)
        expect(Flexitime.parse("01/08/99").year).to eq(1999)
      end

      it "returns a time for a date string with the year set using the ambiguous year future bias of 70" do
        allow(Time.zone).to receive(:now).and_return(Time.zone.local(2020, 1, 1))
        Flexitime.configuration.ambiguous_year_future_bias = 70
        expect(Flexitime.parse("01/08/00").year).to eq(2000)
        expect(Flexitime.parse("01/08/49").year).to eq(2049)
        expect(Flexitime.parse("01/08/50").year).to eq(1950)
        expect(Flexitime.parse("01/08/99").year).to eq(1999)
      end
    end
  end
end
