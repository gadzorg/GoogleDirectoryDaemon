source 'https://rubygems.org'

ruby File.read(".ruby-version").strip

gem 'gram_v2_client', git: "https://github.com/gadzorg/gram2_api_client_ruby"
gem 'gorg_service', '~> 6.0'

gem 'google-api-client'
gem 'googleauth'

gem 'redis', '~>3.2'


group :test do
  gem "simplecov"
  gem "codeclimate-test-reporter", "~> 1.0.0"
end

gem 'byebug'
gem 'webmock'

group :development, :test do
  gem 'rspec'
  gem 'bogus'
  gem "factory_bot"
  gem 'faker'
end
