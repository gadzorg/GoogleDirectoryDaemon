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
          type: "account",
          value: @gram_account.uuid
        },
        {
          type: "custom",
          customType: "uuid",
          value: @gram_account.uuid
        },
        {
          type: "organization",
          value: @gram_account.id_soce
        },
      ]
    }
  end

  def to_google_user
    GUser.new(to_hash)
  end


end