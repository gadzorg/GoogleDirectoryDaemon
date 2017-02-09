#!/usr/bin/env ruby
# encoding: utf-8

require 'gorg_service'

# For default values see : https://github.com/Zooip/gorg_service
GorgService.configure do |c|
  # application name for display usage
  c.application_name= Application.config["application_name"]
  # application id used to find message from this producer
  c.application_id=Application.config["application_id"]

  ## RabbitMQ configuration
  # 
  ### Authentification
  # If your RabbitMQ server is password protected put it here
  #
  c.rabbitmq_user=Application.config['rabbitmq_user']
  c.rabbitmq_password=Application.config['rabbitmq_password']
  #  
  ### Network configuration :
  #
  c.rabbitmq_host=Application.config['rabbitmq_host']
  c.rabbitmq_port=Application.config['rabbitmq_port']
  c.rabbitmq_vhost=Application.config['rabbitmq_vhost']
  #
  #
  # c.rabbitmq_queue_name = c.application_name
  c.rabbitmq_event_exchange_name=Application.config['rabbitmq_event_exchange_name']
  #
  # time before trying again on softfail in milliseconds (temporary error)
  c.rabbitmq_deferred_time=Application.config['rabbitmq_deferred_time']
  # 
  # maximum number of try before discard a message
  c.rabbitmq_max_attempts=Application.config['rabbitmq_max_attempts']
  #
  # The routing key used when sending a message to the central log system (Hardfail or Warning)
  # Central logging is disable if nil
  c.log_routing_key=Application.config['log_routing_key']
  #
  # Routing hash
  #  map routing_key of received message with MessageHandler 
  #  exemple:
  # c.message_handler_map={
  #   "some.routing.key" => MyMessageHandler,
  #   "Another.routing.key" => OtherMessageHandler,
  #   "third.routing.key" => MyMessageHandler,
  # }

  c.logger=Application.logger
end