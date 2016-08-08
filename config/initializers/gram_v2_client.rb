require 'gram_v2_client'

GramV2Client.configure do |c|
  c.site=GoogleDirectoryDaemon.config["gram_api_host"]
  c.user=GoogleDirectoryDaemon.config["gram_api_user"]
  c.password=GoogleDirectoryDaemon.config["gram_api_password"]
end