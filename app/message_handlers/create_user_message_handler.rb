#!/usr/bin/env ruby
# encoding: utf-8

class CreateUserMessageHandler < BaseMessageHandler
  # Respond to routing key: request.gapps.create

  def process
    data=msg.data
    create_user(data)
  end

  # Expect data to contain :
  #  -name
  #  -password
  #  -primary_email
  def create_user data
    if data.values_at(:name,:password,:primary_email).all?
      unless GUser.find(data[:primary_email])
        user=GUser.new
        user.update!(**data)
        user.save
        puts " [x] User #{data[:primary_email]} created"
      else
        raise_softfail "Existing User"
      end
    else
      raise_hardfail "Invalid Data"
    end
  end  
end