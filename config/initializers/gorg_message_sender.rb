GorgMessageSender.configure do |c|

  # Id used to set the event_sender_id
  c.application_id = Application.config["application_id"]

  # RabbitMQ network and authentification
  c.host = Application.config['rabbitmq_host']
  c.port = Application.config['rabbitmq_port']
  c.vhost = Application.config['rabbitmq_vhost']
  c.user = Application.config['rabbitmq_user']
  c.password = Application.config['rabbitmq_password']

  # Exchange configuration
  c.exchange_name = Application.config['rabbitmq_exchange_name']
  c.durable_exchange= true
end