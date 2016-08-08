#!/usr/bin/env ruby
# encoding: utf-8
GUser=Google::Apis::AdminDirectoryV1::User
class Google::Apis::AdminDirectoryV1::User
  #
  # Add methods to Google::Apis::AdminDirectoryV1::User to have a pseudo
  # ActiveModel behaviour
  #

  # @return [Boolean]
  #  Used to cache existence of this user in Google Apps Directory
  attr_accessor :persisted


  # Save user data in Google Apps Directory either by patching existing
  # account or creating a new one
  #
  # @return [Google::Apis::AdminDirectoryV1::User]
  #  Google::Apis::AdminDirectoryV1::User updated with Google Directory data
  def save
    if persisted?
      self.update_from_user_obj!(self.class.service.patch_user(self.primary_email, self))
    else
      self.update_from_user_obj!(self.class.service.insert_user(self))
    end
    self
  end


  # Delete User from Google Apps Directory
  #
  # @return [Nil]
  def delete
    response=self.class.service.delete_user self.primary_email
    self.persisted=false
    response
  end

  # Test if user already exist in Google Apps Directory
  # Use cache if available
  #
  # @param [Boolean] force
  #  Force API querying and reset persistance caching
  #
  # @return [Boolean]
  def persisted? force: false
    if self.persisted && !force
      return true
    else
      self.persisted = false
      if self.class.find self.primary_email
        self.persisted = true
        return true
      else
        return false
      end
    end
  end

  # Refresh current User with Google Directory data
  # Return nil if not persisted yet
  def refresh
    if persisted?
      self.update_from_user_obj!(self.class.find self.primary_email)
    end
  end

  # Lookup requested email in Google Directory
  # @return [Google::Apis::AdminDirectoryV1::User]
  #  or nil if not found
  def self.find user_adress
    begin
      user=service.get_user user_adress
      user.persisted=true
      user
    rescue Google::Apis::ClientError => e
      if JSON.parse(e.body)['error']['code'] == 404
        return nil
      else
        raise e
      end
    end
  end

  # Undelete requested email in Google Directory
  def self.undelete primary_email
    service.undelete_user primary_email
  end

  # @return [DirectoryService]
  #  Service used to perform API calls
  def self.service
    @service||=DirectoryService.new
  end

    # Copy provided user data in current user data
    def update_from_user_obj! u_obj
      self.update!(u_obj.to_h)
    end

end