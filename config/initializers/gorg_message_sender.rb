GorgMessageSender.configure do |c|

  # Id used to set the event_sender_id
  c.application_id = GoogleDirectoryDaemon.config["application_id"]

  # RabbitMQ network and authentification
  c.host = GoogleDirectoryDaemon.config['rabbitmq_host']
  c.port = GoogleDirectoryDaemon.config['rabbitmq_port']
  c.vhost = GoogleDirectoryDaemon.config['rabbitmq_vhost']
  c.user = GoogleDirectoryDaemon.config['rabbitmq_user']
  c.password = GoogleDirectoryDaemon.config['rabbitmq_password']

  # Exchange configuration
  c.exchange_name = GoogleDirectoryDaemon.config['rabbitmq_exchange_name']   
  c.durable_exchange= true
end