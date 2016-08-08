#!/usr/bin/env ruby
# encoding: utf-8

class DeleteUserMessageHandler < BaseMessageHandler
  # Respond to routing key: request.gapps.delete

  def process

    #The value can be the user's primary email address, alias email address, or unique user ID.
    @key=msg.data[:google_account_key]

    GoogleDirectoryDaemon.logger.debug("Received key = #{@key}")

    begin
      gu=GUser.find(@key)
    rescue Google::Apis::ClientError => e
       GoogleDirectoryDaemon.logger.error("Error when retrieving google account #{@key} : #{e.inspect}")
      raise_hardfail "Google apps error", error: e
    end

    raise_google_account_not_found unless gu
    GoogleDirectoryDaemon.logger.debug {"Google account #{@key} primary email = #{gu.primary_email}"} if gu.primary_email != @key


    begin
      gu.delete
      GoogleDirectoryDaemon.logger.info("Successfully deleted account #{gu.primary_email}")
    rescue Google::Apis::ClientError => e
       GoogleDirectoryDaemon.logger.error("Error when deleting #{gu.primary_email} : #{e.inspect}")
      raise_hardfail "Google apps error", error: e
    end
  end


  def raise_google_account_not_found
    GoogleDirectoryDaemon.logger.error("Google account #{@key} does bot exist")
    raise_hardfail("Google account #{@key} does bot exist")
  end
  
end