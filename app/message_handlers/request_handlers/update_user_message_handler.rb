#!/usr/bin/env ruby
# encoding: utf-8
require "json-schema"

class UpdateUserMessageHandler < GorgService::Consumer::MessageHandler::RequestHandler

  listen_to 'request.googleapps.user.update'

  SCHEMA={
      "$schema"=>"http://json-schema.org/draft-04/schema#",
      "title"=> "Update Google Account message schema",
      "type"=>"object",
      "properties"=>{
          "gram_account_uuid"=>{
              "type"=>"string",
              "description"=>"The unique identifier of linked GrAM Account",
              "pattern"=>"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
          },
          "primary_email"=>{
              "type"=>"string",
              "description"=>"Primary email address uof google account"
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
      "required"=>["gram_account_uuid"]
  }

  def validate_payload
    message.validate_data_with(SCHEMA)
    Application.logger.debug "Message data validated"
  end

  def process
    @gram_account=retrieve_gram_data
    Application.logger.debug("Gram account :\n #{@gram_account.inspect}")
  
    unless @gram_account.gapps_id
      #raise_no_registered_google_account 
    else

      service=GramToGoogleService.new(@gram_account)
      gu=service.to_google_user
      Application.logger.debug {"Google User params : #{gu.to_h.merge({password:"HIDDEN"})}"}

      gu.primary_email= primary_email if primary_email

      begin
        gu=GUser.service.patch_user(gu.id, gu)
        Application.logger.info "Google account  #{gu.id} (#{gu.primary_email}) successfully updated"
      rescue Google::Apis::ClientError => e
        case e.message
        when "notFound: Resource Not Found: userKey"
          Application.logger.error("Google Account #{gu.id} does not exists")
          raise_hardfail("Google Account #{gu.id} does not exists",error:e, error_name: 'NotExistingGoogleAccount', status_code: 400)
        else
          raise
        end
      end

      if aliases
        begin
          GoogleUserAliasesManagerService.new(gu,aliases).process
        end
      end

      notify_success(uuid,@gram_account.gapps_id)
    end

  end

  def notify_success(_uuid,google_id)
    data={
        uuid: _uuid.to_s,
        google_id: google_id.to_s
    }
    reply_with(
        data: data,
        status_code: 200
    )
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

  def raise_no_registered_google_account
    Application.logger.error("Accound #{uuid} does not have a google acount registrered")
    raise_hardfail("Accound #{uuid} does not have a google acount registrered")
  end

end
