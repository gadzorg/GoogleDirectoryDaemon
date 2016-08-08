#!/usr/bin/env ruby
# encoding: utf-8


##Abstract class for payload validation and handling connectivity process
# Children classes should implement :
#  - process() : process the message stored in msg
#  - validate_payload() : method used to validate message's payload format
#                         Returns a boolean (true = valid, false = invalid)
#                         If not implemented, returns true
class BaseMessageHandler < GorgService::MessageHandler
  # Respond to routing key: request.gapps.create

  def initialize incoming_msg
    @msg=incoming_msg

    # validate_payload method should be implemented by children classes
    validate_payload

    begin
      # process method should be implemented by children classes
      process
    end
  end

  #convenience method
  def msg
    @msg
  end

  ## Children implemented methods

  # process MUST be implemented
  # If not, raise hardfail
  def process
    GoogleDirectoryDaemon.logger.error("#{self.class} doesn't implement process()")
    raise_hardfail("#{self.class} doesn't implement process()", UnimplementedMessageHandlerError)
  end

  # validate_payload MAY be implemented
  # If not, assumes messages is valid, log a warning and returns true
  def validate_payload
    GoogleDirectoryDaemon.logger.warn("#{self.class} doesn't validate_payload(), assume payload is valid")
    true
  end


  ## Errors management


  # To be raised in case of connection errors with Gram API server
  def raise_gram_connection_error
    GoogleDirectoryDaemon.logger.error("Unable to connect to GrAM API server")
    raise_softfail("Unable to connect to GrAM API server")
  end

  def raise_gram_account_not_found(value)
    GoogleDirectoryDaemon.logger.error("Account not found in Gram - UUID= #{value}")
    raise_hardfail("Account not found in Gram - UUID= #{value}",error: GramAccountNotFoundError)
  end

  def raise_not_updated_group(ldap_group)
    GoogleDirectoryDaemon.logger.error("Unable to save group #{ldap_group.cn} : #{ldap_group.errors.messages.inspect}")
    raise_hardfail("Unable to save group #{ldap_group.cn} : #{ldap_group.errors.messages.inspect}")
  end
end

## Error classes

class InvalidPayloadError < StandardError; end
class UnimplementedMessageHandlerError < StandardError; end
class GramAccountNotFoundError < StandardError; end