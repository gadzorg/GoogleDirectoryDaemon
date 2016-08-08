require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'factory_girl'

$LOAD_PATH.unshift File.expand_path('../../app', __FILE__)
require 'google_directory_daemon'

 ENV['GOOGLE_DIRECTORY_DAEMON_ENV']="test"

RSpec.configure do |config|

  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.find_definitions
  end


  config.mock_with :rspec do |mocks|

    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end
end

require 'support/factories'