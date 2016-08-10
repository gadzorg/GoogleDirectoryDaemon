class GramToGoogleService

  def initialize(gram_account)
    @gram_account=gram_account
  end

  def to_hash
    {
      name: {
        given_name: @gram_account.firstname,
        family_name: @gram_account.lastname,
      },
      password: @gram_account.password,
      hash_function: "SHA-1",
      primary_email: @gram_account.gapps_email,
      external_ids:[
        {
          type: "custom",
          customType: "id_soce",
          value: @gram_account.id_soce
        },
        {
          type: "organization",
          value: @gram_account.uuid
        },
      ]
    }
  end

  def to_google_user
    GUser.new(to_hash)
  end


end