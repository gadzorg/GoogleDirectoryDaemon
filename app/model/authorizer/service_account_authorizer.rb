#!/usr/bin/env ruby
# encoding: utf-8

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'googleauth/stores/redis_token_store'
require 'json'

class ServiceAccountAuthorizer
  class << self

    CREDENTIALS_FILE_PATH=File.expand_path("secrets/service_account_credentials.json",Application.root)
    SCOPE = 'https://www.googleapis.com/auth/admin.directory.user'



    def authorize
      credentials = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io:json_key_io, scope: SCOPE)

      credentials.sub= Application.config['admin_user_id']
      credentials.fetch_access_token!

      credentials
    end


    def json_key_io
      env_value=ENV["#{Application.prefix}_SERVICE_ACCOUNT_CREDENTIALS"]
      if env_value
        StringIO.new(env_value)
      else
        File.open(CREDENTIALS_FILE_PATH)
      end
    end


  end
end