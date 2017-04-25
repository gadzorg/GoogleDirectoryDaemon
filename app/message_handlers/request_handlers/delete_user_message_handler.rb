#!/usr/bin/env ruby
# encoding: utf-8

class DeleteUserMessageHandler < GorgService::Consumer::MessageHandler::RequestHandler

  listen_to 'request.googleapps.user.update'

  def process

    #The value can be the user's primary email address, alias email address, or unique user ID.
    @key=msg.data[:google_account_key]

    Application.logger.debug("Received key = #{@key}")

    begin
      gu=GUser.find(@key)
    rescue Google::Apis::ClientError => e
      Application.logger.error("Error when retrieving google account #{@key} : #{e.inspect}")
      raise_hardfail "Google apps error", error: e
    end

    raise_google_account_not_found unless gu
    Application.logger.debug {"Google account #{@key} primary email = #{gu.primary_email}"} if gu.primary_email != @key


    begin
      gu.delete
      Application.logger.info("Succesfully deleted account #{gu.primary_email}")
      notify_success(@key)
    rescue Google::Apis::ClientError => e
       Application.logger.error("Error when deleting #{gu.primary_email} : #{e.inspect}")
      raise_hardfail "Google apps error", error: e
    end
  end

  def notify_success(key)
    data={
      key: key
    }
    GorgMessageSender.send_message(data,"notify.googleapps.user.deleted")
  end


  def raise_google_account_not_found
    Application.logger.error("Google account #{@key} does bot exist")
    raise_hardfail("Google account #{@key} does bot exist")
  end
  
end