require 'spec_helper'

RSpec.describe GramToGoogleService, type: :service do

  let(:gram_account) {build(:gram_account_with_password)}

  it "initialize a service" do
    expect(GramToGoogleService.new(gram_account)).to be_a_kind_of(GramToGoogleService)
  end

  it "returns update attributes hash" do
    service=GramToGoogleService.new(gram_account)
    expected_hash={ :name=>{
        :given_name=>"Berniece",
        :family_name=>"Welch"
      },
      :password=>"96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6",
      :hash_function=>"SHA-1",
      :external_ids=>[
        {:type=>"custom", customType:"id_soce", :value=>123489},
        {:type=>"organization", :value=>"bfd1c2a2-9876-41f8-8a6a-a7caaa7019e7"},
      ]
    }

    expect(service.to_hash).to include(expected_hash)
  end

  it "returns a google user" do
    service=GramToGoogleService.new(gram_account)
    gu=service.to_google_user

    expect(gu.name).to eq({:given_name=>"Berniece", :family_name=>"Welch"})
    expect(gu.password).to eq("96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6")
    expect(gu.hash_function).to eq("SHA-1")
    expect(gu.external_ids).to match_array([{:type=>"custom", customType:"id_soce", :value=>123489},
        {:type=>"organization", :value=>"bfd1c2a2-9876-41f8-8a6a-a7caaa7019e7"},])
  end

end
