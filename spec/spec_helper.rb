require "simplecov"
SimpleCov.start

require 'factory_bot'

require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true, allow: %w[www.googleapis.com admin.googleapis.com])

APP_PATH = File.expand_path('../../config/boot', __FILE__)
ENV['RAKE_ENV']="test"

require APP_PATH



RSpec.configure do |config|

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end


  config.mock_with :rspec do |mocks|

    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end
end

require 'faker'
require 'support/factories'

