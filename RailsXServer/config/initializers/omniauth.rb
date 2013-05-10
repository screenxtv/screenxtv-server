
if Rails.env.production?
  TWITTER_NEWS={
    consumer_key:"Ve2c9FEbmgBxTD3Tcg5mWw",
    consumer_secret:"jFqj9ARRLFHvHnEoqm95BIWXEboIh1qOLb5KPv2WCg",
    oauth_token:"1003487647-27gvEUidncxAJJ506TOu5CbpmtCwPziqtbf17B3",
    oauth_token_secret:"lZvuckd6MRTcNvySGZmCHZjkhkIhdMDJIbtB7js4aak"
  }
elsif Rails.env.development?
  TWITTER_NEWS={
    consumer_key:"2GCasYV20FLrBhaMgogHw",
    consumer_secret:"U1InFQ4UuqGMCPS177YFSJ6HtZuE8SSSfT49VcOPQc",
    oauth_token:"1003487647-27gvEUidncxAJJ506TOu5CbpmtCwPziqtbf17B3",
    oauth_token_secret:"NSfjqvlrma604ZYaWDzqOkKOiLU48690vfISaTP0fHY"
  }
else
  TWITTER_NEWS={}
end

OAuthConsumers = {
  'twitter' => {
    consumer_key:"pJ2F7coxlc5jlKcmSPrLqQ",
    consumer_secret:"n0qURhYbR8ugJfET12fhb1ko4vJD18e8Kmuxlk3M884"
  },
  'facebook' => {
    consumer_key:"508541325870692",
    consumer_secret:"a625d91dec4d294f484e563e35e8d381"
  }
}

Rails.application.config.middleware.use OmniAuth::Builder do
  OAuthConsumers.each do |provider, data|
    provider provider.to_sym, data[:consumer_key], data[:consumer_secret]
  end
end
