require 'gorg_service/rspec/bunny_cleaner'
require 'gorg_service/rspec/log_message_handler'

RSpec.configure do |c|
  c.before(:context, type: :integration) {GorgService.configuration.rabbitmq_client_class=BunnyCleaner}
  c.around(:example,type: :integration) do |example|
    BunnyCleaner.cleaning do
      begin
        GramAccountMocker.reset!
        LogMessageHandler.reset_listen_to!
        LogMessageHandler.listen_to Application.config['log_routing_key']
        LogMessageHandler.reset

        defined?(before_start_proc) && before_start_proc.call

        @app=Application.new
        @app.start
        begin
          example.run
        ensure
          @app.stop
        end
      ensure
        if defined?(skip_cleanup)
          Application.logger.info "### CLEAN GSuite Users skipped"
          next
        end

        Application.logger.info "#### CLEANING UP GSuite Users"
        sleep 1 # Google API may not be always sync just after creation...

        # TODO: handle case where it's expected to not find an user
        begin
          Timeout.timeout(3) do
            loop do
              g_user = GUser.find(user_email)
              if g_user.nil?
                sleep 0.5
              else
                g_user.delete
                break
              end
            end
          end
        rescue Timeout::Error
          # NOOP, maybe expected
        end
      end
    end
  end
end

# Inspired from https://github.com/laserlemon/rspec-wait/blob/master/lib/rspec/wait/handler.rb
def wait_for(timeout: 10, sleep_between: 0.3, &block)
  Timeout.timeout(timeout) do
    begin
      condition = yield
      break true if condition
    rescue RSpec::Expectations::ExpectationNotMetError
      sleep sleep_between
      retry
    end
  end
rescue Timeout::Error
  yield # will fail with expectaction error, not timeout error
end
