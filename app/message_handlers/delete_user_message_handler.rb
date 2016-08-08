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

  # Expect data to contain :
  #  -name
  #  -password
  #  -primary_email
  def create_user data
    if data.values_at(:name,:password,:primary_email).all?
      unless GUser.find(data[:primary_email])
        user=GUser.new
        user.update!(**data)
        user.save
        puts " [x] User #{data[:primary_email]} created"
      else
        raise_softfail "Existing User"
      end
    else
      raise_hardfail "Invalid Data"
    end
  end  

  def set_uuid
    @uuid=msg.data[:uuid]
    unless @uuid
      #TODO handle null hruid, maybe by validating the message JSON
    end
  end

  def retrieve_gram_data
    begin
      #retrieve data from Gram, with password
      GramV2Client::Account.find(@uuid, params:{show_password_hash: "true"})
    rescue ActiveResource::ResourceNotFound
      raise_gram_account_not_found(@uuid)
    rescue ActiveResource::ServerError
      raise_gram_connection_error
    end
  end

  def raise_google_account_not_found
    GoogleDirectoryDaemon.logger.error("Google account #{@key} does bot exist")
    raise_hardfail("Google account #{@key} does bot exist")
  end

  def raise_no_gapps_email_error
    GoogleDirectoryDaemon.logger.error("Accound #{@uuid} does bot have a Gapps email")
    raise_hardfail("Accound #{@uuid} does bot have a Gapps email")
  end

end