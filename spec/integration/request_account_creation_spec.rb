require "base64"

require 'spec_helper'
require 'support/integrations_tools'
require 'gram_v2_client/rspec/gram_account_mocker'


RSpec.describe "Request an account creation", type: :integration do

  let(:before_start_proc) {Proc.new{LogMessageHandler.listen_to "reply.googleapps.user.create"}}

  let(:user_name) {Faker::Internet.user_name(Faker::Name.name)}
  let(:user_email) {"#{user_name}@poubs.org"}
  let(:aliases) {["#{user_name}_2@poubs.org","#{user_name}_3@poubs.org"]}
  let(:valid_create_user_payload) {{
      gram_account_uuid: "12345678-1234-1234-1234-123456789012",
      primary_email: user_email,
      aliases: aliases
  }}

  let(:message) {GorgService::Message.new(event:'request.googleapps.user.create',
                                          data:valid_create_user_payload,
                                          reply_to: Application.config['rabbitmq_event_exchange_name'])}

  context "with no registered gapps" do
    let(:gapps_id) {nil}
    let(:gam) {GramAccountMocker.for(attr:{uuid: "12345678-1234-1234-1234-123456789012",
                                           gapps_id: gapps_id,
                                           password:'96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6'},
                                     auth: GramAccountMocker.http_basic_auth_header(Application.config["gram_api_user"],
                                                                                    Application.config["gram_api_password"])
                                    )}

    before(:each) do
      gam.mock_get_request(with_password:true)
      gam.mock_put_request
    end

    context "not existing gapps" do
      before(:each) do
        GorgService::Producer.new.publish_message(message)
        sleep(10)
      end

      it "it create a user in Google apps" do
        g_user=GUser.find(user_email)
        expect(g_user).not_to be_nil
      end

      it "store gapps id in GrAM" do
        g_user=GUser.find(user_email)
        last_put_request=ActiveResource::HttpMock.requests.select{|r| r.method==:put && r.path==gam.uri_for_get_request}.last
        expect(JSON.parse(last_put_request.body)['gapps_id']).to eq(g_user.id)
      end

      it "respond to the request with success" do
        g_user=GUser.find(user_email)
        expect(LogMessageHandler).to have_received_a_message_with_routing_key("reply.googleapps.user.create")
        reply=LogMessageHandler.messages.select{|m| m.routing_key=="reply.googleapps.user.create"}.last
        expect(reply.correlation_id).to eq(message.id)
        expect(reply.data[:status]).to eq("success")
        expect(reply.data[:uuid]).to eq("12345678-1234-1234-1234-123456789012")
        expect(reply.data[:google_id]).to eq(g_user.id)
      end

      it "doesn't raise hardfail" do
        expect(LogMessageHandler).not_to have_received_error("harderror")
      end
    end

    context "existing gapps" do
      before(:each) do
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

        GorgService::Producer.new.publish_message(message)
        sleep(10)
      end

      it "it doesn't change GUser attributes" do
        g_user=GUser.find(user_email)
        expect(g_user).not_to be_nil
        expect(g_user.name.given_name).to eq("Old firstname")
      end

      it "Does not modify data stored in gram GrAM" do
        last_put_request=ActiveResource::HttpMock.requests.select{|r| r.method==:put && r.path==gam.uri_for_get_request}.last
        expect(last_put_request).to be_nil
      end

      it "respond to the request with an error" do
        expect(LogMessageHandler).to have_received_a_message_with_routing_key("reply.googleapps.user.create")
        reply=LogMessageHandler.messages.select{|m| m.routing_key=="reply.googleapps.user.create"}.last
        expect(reply.correlation_id).to eq(message.id)
        expect(reply.data[:status]).to eq("hardfail")
      end

      it "raise hardfail" do
        expect(LogMessageHandler).to have_received_error("harderror")
      end
    end

  end

  context "with registered gapps" do
    let(:gapps_id) {"some_gapps_id"}
    let(:gam) {GramAccountMocker.for(attr:{uuid: "12345678-1234-1234-1234-123456789012",
                                           gapps_id: gapps_id},
                                     auth: ("Basic "+Base64.encode64(Application.config["gram_api_user"]+':'+Application.config["gram_api_password"]).chomp))}
    before(:each) {gam.mock_get_request(with_password:true)}

    before(:each) do
      GorgService::Producer.new.publish_message(message)
      sleep(2)
    end

    it "Does not create a GUser" do
      g_user=GUser.find(user_email)
      expect(g_user).to be_nil
    end

    it "Does not modify data stored in gram GrAM" do
      last_put_request=ActiveResource::HttpMock.requests.select{|r| r.method==:put && r.path==gam.uri_for_get_request}.last
      expect(last_put_request).to be_nil
    end

    it "respond to the request with an error" do
      expect(LogMessageHandler).to have_received_a_message_with_routing_key("reply.googleapps.user.create")
      reply=LogMessageHandler.messages.select{|m| m.routing_key=="reply.googleapps.user.create"}.last
      expect(reply.correlation_id).to eq(message.id)
      expect(reply.data[:status]).to eq("hardfail")
    end

    it "it raise a Hardfail" do
      expect(LogMessageHandler).to have_received_error("harderror")
    end
  end
end