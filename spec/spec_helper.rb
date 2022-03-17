# frozen_string_literal: true

# Initiate code coverage but not when running appraisal
# to prevent an error with activesupport 4.0
# View test coverage report after running test suite by using the following command
# > open coverage/index.html
# https://github.com/simplecov-ruby/simplecov
if ENV["APPRAISAL_INITIALIZED"].nil?
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require "flexitime"

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
