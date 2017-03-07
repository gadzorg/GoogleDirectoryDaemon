require "base64"

require 'spec_helper'
require 'support/integrations_tools'
require 'gram_v2_client/rspec/gram_account_mocker'


RSpec.describe "Request an account update", type: :integration do

  let(:before_start_proc) {Proc.new{LogMessageHandler.listen_to "reply.googleapps.user.update"}}

  let(:user_name) {Faker::Internet.user_name(Faker::Name.name)}
  let(:user_email) {"#{user_name}@poubs.org"}
  let(:aliases) {["#{user_name}_2@poubs.org","#{user_name}_3@poubs.org"]}
  let(:valid_create_user_payload) {{
      gram_account_uuid: "12345678-1234-1234-1234-123456789012",
      primary_email: user_email,
      aliases: aliases
  }}

  let(:message) {GorgService::Message.new(event:'request.googleapps.user.update',
                                          data:valid_create_user_payload,
                                          reply_to: Application.config['rabbitmq_event_exchange_name'])}


  context "existing GUser" do
    let!(:g_user) do
      GUser.new({
                    name: {
                        given_name: "Old firstname",
                        family_name: "Old lastname",
                    },
                    password: '96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6',
                    hash_function: "SHA-1",
                    primary_email: user_email
                }
      ).save
    end

    let(:gapps_id) {g_user.id}
    let(:gam) {GramAccountMocker.for(attr:{uuid: "12345678-1234-1234-1234-123456789012",
                                           gapps_id: gapps_id,
                                           password:'96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6',
                                           firstname: "New firstname",
                                           lastname: "New lastname"},
                                     auth: GramAccountMocker.http_basic_auth_header(Application.config["gram_api_user"],
                                                                                    Application.config["gram_api_password"])
                                    )}
    before(:each) {gam.mock_get_request(with_password:true)}
    before(:each) do
      GorgService::Producer.new.publish_message(message)
      sleep(10)
    end

    it "update the GUser" do
      gu=GUser.find(user_email)
      expect(gu.name.given_name).to eq("New firstname")
      expect(gu.name.family_name).to eq("New lastname")
    end

    it "doesn't raise hardfail" do
      expect(LogMessageHandler).not_to have_received_error("harderror")
    end


    it "respond to the request with success" do
      gu=GUser.find(user_email)
      expect(LogMessageHandler).to have_received_a_message_with_routing_key("reply.googleapps.user.update")
      reply=LogMessageHandler.messages.select{|m| m.routing_key=="reply.googleapps.user.update"}.last
      expect(reply.correlation_id).to eq(message.id)
      expect(reply.data[:status]).to eq("success")
      expect(reply.data[:uuid]).to eq("12345678-1234-1234-1234-123456789012")
      expect(reply.data[:google_id]).to eq(gu.id)
    end


  end

  context "Not existing GUser" do


    let(:gapps_id) {"987654321123456789987654321"}
    let(:gam) {GramAccountMocker.for(attr:{uuid: "12345678-1234-1234-1234-123456789012",
                                           gapps_id: gapps_id},
                                     auth: GramAccountMocker.http_basic_auth_header(Application.config["gram_api_user"],
                                                                                    Application.config["gram_api_password"]))}
    before(:each) {gam.mock_get_request(with_password:true)}

    before(:each) do
      GorgService::Producer.new.publish_message(message)
      sleep(2)
    end

    it "Does not modify data stored in GrAM" do
      last_put_request=ActiveResource::HttpMock.requests.select{|r| r.method==:put && r.path==gam.uri_for_get_request}.last
      expect(last_put_request).to be_nil
    end

    it "respond to the request with an error" do
      expect(LogMessageHandler).to have_received_a_message_with_routing_key("reply.googleapps.user.update")
      reply=LogMessageHandler.messages.select{|m| m.routing_key=="reply.googleapps.user.update"}.last
      expect(reply.correlation_id).to eq(message.id)
      expect(reply.data[:status]).to eq("hardfail")
    end

    it "it raise a Hardfail" do
      expect(LogMessageHandler).to have_received_error("harderror")
    end

  end
end