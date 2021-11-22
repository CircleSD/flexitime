# frozen_string_literal: true

# load a file relative to the current location
require_relative "lib/flexitime/version"

Gem::Specification.new do |spec|
  spec.name          = "flexitime"
  spec.version       = Flexitime::VERSION
  spec.authors       = ["Chris Hilton"]
  spec.email         = ["449774+chrismhilton@users.noreply.github.com"]

  spec.summary       = "Ruby date/time string parser"
  spec.description   = "Ruby date/time string parser for common formats and different date orders"
  spec.homepage      = "https://github.com/CircleSD/flexitime"
  spec.license       = "MIT"

  # Minimum version of Ruby that the gem works with
  spec.required_ruby_version = ">= 2.5.0"

  # Metadata used on gem’s profile page on rubygems.org
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/CircleSD/flexitime/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/CircleSD/flexitime/issues"
  spec.metadata["documentation_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  # Binary folder where the gem’s executables are located
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  # Add lib directory to $LOAD_PATH to make code available via the require statement
  spec.require_paths = ["lib"]

  # Register runtime and development dependencies
  # including gems that are essential to test and build this gem
  # whereas gems like rubocop or standard are not essential are included in the Gemfile
  spec.add_dependency "activesupport", ">= 4.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "appraisal"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
