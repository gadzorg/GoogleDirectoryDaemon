
# This service is in charge of creating and deleting user's aliases to match givens tate
#
# All Google API call are made in a single HTTP request using google batch API
# https://developers.google.com/admin-sdk/directory/v1/guides/batch
#
# You MUST NOT specify aliases extracted from domain aliases (ex : gadz.fr for gadz.org)
# They are created automatically and are not valid user defined aliases
#
# Exemple :
#  User "john.doe@gadz.org" have 2 aliases : "jd@gadz.org" and "bucque@gadz.org"
#  We went him to have this aliases : "bucque@gadz.org" and "jd2011@gadz.org"
# 
#    g_user = GUser.find("john.doe@gadz.org")
#    target_aliases = ["bucque@gadz.org","jd2011@gadz.org"]
#    alias_manager = GoogleUserAliasesManagerService.new(g_user, target_aliases)
#    alias_manager.process
#
#  this will delete alias "jd@gadz.org" and create "jd2011@gadz.org", leaving
#  "bucque@gadz.org" untouched
#
class GoogleUserAliasesManagerService

  def initialize (user, aliases)
    @user=user
    @target_aliases=aliases
  end

  def process
    Application.logger.debug "Current aliases : #{@user.all_aliases}"
    Application.logger.debug "Target aliases  : #{@target_aliases}"
    Application.logger.debug "Aliases to add  : #{to_create_aliases}"
    Application.logger.debug "Aliases to del  : #{to_remove_aliases}"

    if to_remove_aliases.any?||to_create_aliases.any?
      gservice.batch do
        to_remove_aliases.each do |a|
          remove_alias a
        end

        to_create_aliases.each do |a|
          add_alias a
        end
      end
      Application.logger.info "Aliases for #{@user.id} updated"
    else
      Application.logger.info "Aliases for #{@user.id} have not changed"
    end
  end

  private

    def add_alias a
      ga=Google::Apis::AdminDirectoryV1::Alias.new(alias: a)
      gservice.insert_user_alias(user_key,ga)
      Application.logger.debug "Ordered to create alias #{a}"
    end

    def remove_alias a
      gservice.delete_user_alias(user_key,a)
      Application.logger.debug "Ordered to delete alias #{a}"
    end

    def user_key
      @user.id
    end

    def to_create_aliases
      @target_aliases-@user.all_aliases
    end

    def to_remove_aliases
      (@user.aliases||[])-@target_aliases
    end

    def gservice
      @gservice||=DirectoryService.new
    end




end