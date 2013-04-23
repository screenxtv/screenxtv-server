if Rails.env.production?
  TWITTER_NEWS={
    consumer_key:"Ve2c9FEbmgBxTD3Tcg5mWw",
    consumer_secret:"jFqj9ARRLFHvHnEoqm95BIWXEboIh1qOLb5KPv2WCg",
    oauth_token:"1003487647-27gvEUidncxAJJ506TOu5CbpmtCwPziqtbf17B3",
    oauth_token_secret:"lZvuckd6MRTcNvySGZmCHZjkhkIhdMDJIbtB7js4aak"
  }
else
  TWITTER_NEWS={
    consumer_key:"2GCasYV20FLrBhaMgogHw",
    consumer_secret:"U1InFQ4UuqGMCPS177YFSJ6HtZuE8SSSfT49VcOPQc",
    oauth_token:"1003487647-27gvEUidncxAJJ506TOu5CbpmtCwPziqtbf17B3",
    oauth_token_secret:"NSfjqvlrma604ZYaWDzqOkKOiLU48690vfISaTP0fHY"
  }
end

module OAuthConsumers
  PROVIDERS=[:twitter]
  TWITTER={
    site:"http://api.twitter.com",
    consumer_key:"pJ2F7coxlc5jlKcmSPrLqQ",
    consumer_secret:"n0qURhYbR8ugJfET12fhb1ko4vJD18e8Kmuxlk3M884"
  }
end
