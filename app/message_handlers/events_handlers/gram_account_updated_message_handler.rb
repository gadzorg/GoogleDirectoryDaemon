class GramAccountUpdatedMessageHandler < GorgService::Consumer::MessageHandler::EventHandler
  # Respond to routing key: request.gapps.create

  listen_to "notify.account.updated"

  def process
    proxy_msg=message.dup
    proxy_msg.data=message.data.dup
    proxy_msg.data[:gram_account_uuid]=proxy_msg.data[:key]
    UpdateUserMessageHandler.new proxy_msg
  end

end