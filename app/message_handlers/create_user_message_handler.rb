#!/usr/bin/env ruby
# encoding: utf-8

class CreateUserMessageHandler < BaseMessageHandler
  # Respond to routing key: request.gapps.create

  def process
    set_uuid
    @gram_account=retrieve_gram_data
    GoogleDirectoryDaemon.logger.debug("(uuid) = #{@uuid}")

    raise_no_gapps_email_error unless @gram_account.gapps_email

    service=GramToGoogleService.new(@gram_account)
    GoogleDirectoryDaemon.logger.debug {service.to_hash.merge({password:"HIDDEN"})}

    gu=service.to_google_user
    action= gu.persisted? ? "update" : "create"

    begin
      gu.save
      GoogleDirectoryDaemon.logger.info("Successfully updated account #{gu.primary_email} : #{action}")
    rescue Google::Apis::ClientError => e
       GoogleDirectoryDaemon.logger.error("Error when saving #{gu.primary_email} : #{e.inspect}")
      raise_hardfail "Invalid Data", error: e
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

  def raise_no_gapps_email_error
    GoogleDirectoryDaemon.logger.error("Accound #{@uuid} does bot have a Gapps email")
    raise_hardfail("Accound #{@uuid} does bot have a Gapps email")
  end

end