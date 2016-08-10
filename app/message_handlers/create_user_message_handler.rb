#!/usr/bin/env ruby
# encoding: utf-8
require "json-schema"

class CreateUserMessageHandler < BaseMessageHandler
  # Respond to routing key: request.gapps.account.create

  def process
    @gram_account=retrieve_gram_data
    GoogleDirectoryDaemon.logger.debug("(uuid) = #{uuid}")

    raise_already_registered_google_account if @gram_account.gapps_id

    service=GramToGoogleService.new(@gram_account)
    GoogleDirectoryDaemon.logger.debug {service.to_hash.merge({password:"HIDDEN"})}
    gu=service.to_google_user

    gu.primary_email= primary_email
  
    begin
      gu=GUser.service.insert_user gu
    rescue Google::Apis::ClientError => e
      case e.message
      when "duplicate: Entity already exists."
        GoogleDirectoryDaemon.logger.error("Google Accound #{primary_email} already exists")
        raise_hardfail("Google Accound #{primary_email} already exists")
      else
        GoogleDirectoryDaemon.logger.error("Error when saving #{gu.primary_email} : #{e.inspect}")
        raise_hardfail "Invalid Data", error: e
      end
    end

    @gram_account.update_attribute(:gapps_id,gu.id)
  end

  def uuid
    msg.data[:gram_account_uuid]
  end

  def primary_email
    msg.data[:primary_email]
  end

  def retrieve_gram_data
    begin
      #retrieve data from Gram, with password
      GramV2Client::Account.find(uuid, params:{show_password_hash: "true"})
    rescue ActiveResource::ResourceNotFound
      raise_gram_account_not_found(uuid)
    rescue ActiveResource::ServerError
      raise_gram_connection_error
    end
  end



  def raise_already_registered_google_account
    GoogleDirectoryDaemon.logger.error("Accound #{uuid} already have a google acount registrered")
    raise_hardfail("Accound #{uuid} already have a google acount registrered")
  end


  def validate_payload
    schema={
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

    errors=JSON::Validator.fully_validate(schema, msg.data)
    if errors.any?
      GoogleDirectoryDaemon.logger.error "Data validation error : #{errors.inspect}"
      raise_hardfail("Data validation error", error: errors.inspect)
    end

    GoogleDirectoryDaemon.logger.debug "Message data validated"

  end

end