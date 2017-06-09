#!/usr/bin/env ruby
# encoding: utf-8
require "json-schema"

class CreateUserMessageHandler < GorgService::Consumer::MessageHandler::RequestHandler

  listen_to 'request.googleapps.user.create'

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
    Application.logger.debug("Process...")
    @gram_account=retrieve_gram_data
    Application.logger.debug("Gram account :\n #{@gram_account.inspect}")

    raise_already_registered_google_account(gapps_id: @gram_account.gapps_id) if @gram_account.gapps_id && !(@gram_account.gapps_id.match(/\A\s*\Z/)) #Not blank

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
        raise_hardfail("Google Account #{primary_email} already exists",error:e, error_name: 'ExistingGoogleAccount',data: {uuid: uuid}.merge(google_apps_debug_data(primary_email)), status_code: 400)
      else
        raise
      end
    end

    @gram_account.gapps_id= gu.id
    if @gram_account.save
      Application.logger.info "Gram account #{uuid} successfully updated with google id #{gu.id}"
      notify_success(uuid,gu.id)
    else
      Application.logger.error("Unable to update GrAM gapps_id of account #{uuid}")
      raise_hardfail("Unable to update GrAM gapps_id of account #{uuid}",error_name: 'UnableToSaveGramUser',data: {uuid: uuid, target_data: JSON.parse(ga.to_json).merge("password"=>"Hidden").to_json}, status_code: 500)
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

  def raise_already_registered_google_account(gapps_id: nil)
    Application.logger.error("Account #{uuid} already have a google acount registrered")

    debug_data={
        uuid: uuid,
        gapps_id: gapps_id
    }

    if gapps_id
      debug_data.merge!(google_apps_debug_data(gapps_id))
    end

    raise_hardfail("Account #{uuid} already have a google acount registrered",error_name: 'GoogleAccountAlreadyRegisteredInGrAM',data: debug_data, status_code: 400)
  end

  def google_apps_debug_data(id)
    begin
      target_gapps=GUser.find(id)
      if target_gapps
        {
            :gapps_id => target_gapps.id,
            :gapps_primary_email => target_gapps.primary_email,
            :gapps_external_ids => target_gapps.external_ids.to_json,
            :gapps_last_login => target_gapps.last_login_time.to_s,
        }
      else
        {
            :gapps_search_id => id,
            :gapps_primary_email => "NOT FOUND",
        }
      end
    rescue Google::Apis::ClientError
      {
          :gapps_search_id => id,
          :gapps_primary_email => "Error during API call",
      }
    end

  end

end
