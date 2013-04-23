RailsXServer::Application.routes.draw do
  resources :screens

  root to:'index#index'
  match 'doc/howto',to:'index#howto',as:'doc_howto'
  match 'doc/team',to:'index#team',as:'doc_team'
  match 'screen_notify/:url', to:'screens#notify'
  match 'screens/notify/:url', to:'screens#notify'
  match 'screens/authenticate/:url',to:'screens#authenticate'
  match 'screens/post/:url', to:'screens#post',via:'post',as:'post'
  match 'screens/status/:url(/:key)',to:'screens#status'

  match 'screens.:format',to:'screens#index'

  match 'embed/:url', to:'screens#show_embed'
  match 'screens/post/:room/:id', to:'screens#post',via:'post',as:'post'
  match 'screens/:url', to:'screens#show'
  match 'private/:url', to: 'screens#show_private'

  match 'user/signin',to:'user#signin'
  match 'user/signout',to:'user#signout',via:'delete'
  match 'user/create',to:'user#create',via:'post'
  match 'user/index',to:'user#index'

  match 'oauth/connect/:provider',to:'oauth#connect'
  match 'oauth/disconnect/:provider',to:'oauth#disconnect',via:'delete'
  match 'oauth/callback',to:'oauth#callback'

  match ':url', to:'screens#show'

end
