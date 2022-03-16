# Benchmark file to compare Flexitime with Time and Time.zone parsing
# to ensure Flexitime performs as well as possible
# To perform benchmark comparison run:-
# $ ruby benchmark.rb
$:.unshift(File.expand_path("lib"))

require "benchmark"
require "flexitime"
require "active_support/time"

Time.zone = "Europe/London"

n = 10_000

Benchmark.bm(50) do |benchmark|
  benchmark.report("Time.parse datetime YMD") do
    n.times do
      Time.parse("2021-08-12 12:30")
    end
  end

  benchmark.report("Time.zone.parse datetime YMD") do
    n.times do
      Time.zone.parse("2021-08-12 12:30")
    end
  end

  benchmark.report("Flexitime.parse datetime YMD") do
    n.times do
      Flexitime.parse("2021-08-12 12:30")
    end
  end
end

Benchmark.bm(50) do |benchmark|
  benchmark.report("Time.parse datetime DMY HM") do
    n.times do
      Time.parse("23/08/2021 12:30")
    end
  end

  benchmark.report("Time.zone.parse datetime DMY HM") do
    n.times do
      Time.zone.parse("23/08/2021 12:30")
    end
  end

  benchmark.report("Flexitime.parse datetime DMY HM") do
    n.times do
      Flexitime.parse("23/08/2021 12:30")
    end
  end
end

Benchmark.bm(50) do |benchmark|
  benchmark.report("Time.parse datetime DMY HMS") do
    n.times do
      Time.parse("23/08/2021 12:30:45")
    end
  end

  benchmark.report("Time.zone.parse datetime DMY HMS") do
    n.times do
      Time.zone.parse("23/08/2021 12:30:45")
    end
  end

  benchmark.report("Flexitime.parse datetime DMY HMS") do
    n.times do
      Flexitime.parse("23/08/2021 12:30:45")
    end
  end
end

Benchmark.bm(50) do |benchmark|
  benchmark.report("Time.parse time HM") do
    n.times do
      Time.parse("12:30")
    end
  end

  benchmark.report("Time.zone.parse time HM") do
    n.times do
      Time.zone.parse("12:30")
    end
  end

  benchmark.report("Flexitime.parse time HM") do
    n.times do
      Flexitime.parse("12:30")
    end
  end
end

Benchmark.bm(50) do |benchmark|
  benchmark.report("Time.parse time HMS") do
    n.times do
      Time.parse("12:30:45")
    end
  end

  benchmark.report("Time.zone.parse time HMS") do
    n.times do
      Time.zone.parse("12:30:45")
    end
  end

  benchmark.report("Flexitime.parse time HMS") do
    n.times do
      Flexitime.parse("12:30:45")
    end
  end
end
