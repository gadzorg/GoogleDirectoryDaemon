#!/usr/bin/env ruby
# encoding: utf-8
require "json-schema"

class CreateUserMessageHandler < GorgService::Consumer::MessageHandler::Base
  # Respond to routing key: request.gapps.account.create

  SCHEMA={
      "$schema"=>"http://json-schema.org/draft-04/schema#",
      "title"=> "Create Google Account message schema",
      "type"=>"object",
      "properties"=>{
          "gram_account_uuid"=>{
              "type"=>"string",
              "description"=>"The unique identifier of linked GrAM Account",
              "pattern"=>"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
          },
          "primary_email"=>{
              "type"=>"string",
              "description"=>"Primary email address used to create google account"
          },
          "aliases"=>{
              "type"=>"array",
              "description"=>"Google account email aliases",
              "items"=>{
                  "type"=>"string"
              }
          }
      },
      "additionalProperties"=>true,
      "required"=>["gram_account_uuid", "primary_email"]
  }

  def validate
    message.validate_data_with(SCHEMA)
    Application.logger.debug "Message data validated"
  end

  def process
    @gram_account=retrieve_gram_data
    Application.logger.debug("Gram account :\n #{@gram_account.inspect}")

    raise_already_registered_google_account if @gram_account.gapps_id

    service=GramToGoogleService.new(@gram_account)
    gu=service.to_google_user
    Application.logger.debug {service.to_hash.merge({password:"HIDDEN"})}

    gu.primary_email= primary_email
  
    begin
      gu=GUser.service.insert_user gu
      Application.logger.info "Google account #{primary_email} successfully created with id #{gu.id}"
    rescue Google::Apis::ClientError => e
      case e.message
      when "duplicate: Entity already exists."
        Application.logger.error("Google Account #{primary_email} already exists")
        raise_hardfail("Google Account #{primary_email} already exists")
      else
        raise
      end
    end

    @gram_account.gapps_id= gu.id
    if @gram_account.save
      Application.logger.info "Gram account #{uuid} successfully updated with google id #{gu.id}"
      notify_success(uuid,gu.id)
    else
      Application.logger.error("Unable to update GrAM gapps_id of account #{uuid}" )
      raise_hardfail("Unable to update GrAM gapps_id of account #{uuid}")
    end


    if aliases
      begin
        GoogleUserAliasesManagerService.new(gu,aliases).process
      end
    end
   

  end

  def notify_success(_uuid,google_id)
    data={
      uuid: _uuid.to_s,
      google_id: google_id.to_s
    }
    GorgMessageSender.new.send_message(data,"notify.googleapps.user.created")
  end

  def uuid
    msg.data[:gram_account_uuid]
  end

  def primary_email
    msg.data[:primary_email]
  end

  def aliases
    msg.data[:aliases]
  end

  def retrieve_gram_data
      #retrieve data from Gram, with password
      GramV2Client::Account.find(uuid, params:{show_password_hash: "true"})
  end

  def raise_already_registered_google_account
    Application.logger.error("Accound #{uuid} already have a google acount registrered")
    raise_hardfail("Accound #{uuid} already have a google acount registrered")
  end

end
