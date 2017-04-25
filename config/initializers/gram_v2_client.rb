require 'gram_v2_client'

GramV2Client.configure do |c|
  c.site=Application.config["gram_api_host"]
  c.user=Application.config["gram_api_user"]
  c.password=Application.config["gram_api_password"]
end