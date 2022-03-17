# Appraisal integrates with bundler and rake to test your library
# against different versions of dependencies in repeatable scenarios called "appraisals"
# https://github.com/thoughtbot/appraisal
#
# The dependencies in your Appraisals file are combined with dependencies in your Gemfile
#
# Install the dependencies for each appraisal
# $ bundle exec appraisal install
# which generates a Gemfile for each appraisal in the gemfiles directory
#
# Run each appraisal in turn or a single appraisal:-
# $ bundle exec appraisal rspec
# $ bundle exec appraisal activesupport-6-1 rspec
appraise "activesupport-7-0" do
  gem "activesupport", "~> 7.0"
end

appraise "activesupport-6-1" do
  gem "activesupport", "~> 6.1"
end

appraise "activesupport-6-0" do
  gem "activesupport", "~> 6.0.1"
end

appraise "activesupport-5-2" do
  gem "activesupport", "~> 5.2"
end

appraise "activesupport-5-1" do
  gem "activesupport", "~> 5.1.0"
end

appraise "activesupport-5-0" do
  gem "activesupport", "~> 5.0.1"
end

appraise "activesupport-4-2" do
  gem "activesupport", "~> 4.2"
end

appraise "activesupport-4-1" do
  gem "activesupport", "~> 4.1.0"
end

appraise "activesupport-4-0" do
  gem "activesupport", "~> 4.0.1"
end
