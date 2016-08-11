FactoryGirl.define do
  factory :gram_account, class: GramV2Client::Account do
    uuid "bfd1c2a2-9876-41f8-8a6a-a7caaa7019e7"
    hruid "berniece.welch.1989"
    id_soce 123489
    enabled true
    lastname "Welch"
    firstname "Berniece"
    birthname nil
    birth_firstname nil
    email "user_1@batchexample.com"
    gapps_id "100210089258909044230"
    birthdate nil
    deathdate nil
    gender nil
    is_gadz true
    is_student nil
    school_id nil
    is_alumni nil
    date_entree_ecole nil
    date_sortie_ecole nil
    ecole_entree nil
    buque_texte nil
    buque_zaloeil nil
    gadz_fams nil
    gadz_fams_zaloeil nil
    gadz_proms_principale nil
    gadz_proms_secondaire nil
    avatar_url nil
    description nil
    url "/api/v2/accounts/bfd1c2a2-9876-41f8-8a6a-a7caaa7019e7"

    initialize_with {new(attributes)}

    factory :gram_account_with_password do
      password "96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6"
    end
  end

end

    #  [<GramV2Client::Account::Alias:0x0000000317a888 @attributes={"name"=>"berniece.welch.1989"}, @prefix_options={}, @persisted=true>,
    #   <GramV2Client::Account::Alias:0x00000003178538 @attributes={"name"=>"123489"}, @prefix_options={}, @persisted=true>,
    #   <GramV2Client::Account::Alias:0x000000031782b8 @attributes={"name"=>"berniece.welch"}, @prefix_options={}, @persisted=true>
    # ]

    # <GramV2Client::Group:0x000000031739c0 @attributes={"uuid"=>"a7e047e0-5e2e-43bf-ab85-42d6c27e0e80",
    #  "short_name"=>"goblins",
    #  "name"=>"dragons",
    #  "description"=>"Innovative even-keeled infrastructure",
    #  "url"=>"/api/v2/groups/a7e047e0-5e2e-43bf-ab85-42d6c27e0e80"}, @prefix_options={}, @persisted=true>