# frozen_string_literal: true

require "flexitime"
require "active_support/time" # Time.zone

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

I18n.available_locales = ["en", "en-GB", "en-US", "en-IE", "nl"]
