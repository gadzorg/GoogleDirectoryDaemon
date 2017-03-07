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
        Application.logger.info "#### CLEANING UP GSuite Users"

        g_user=GUser.find(user_email)
        g_user && g_user.delete
      end

    end
  end
end