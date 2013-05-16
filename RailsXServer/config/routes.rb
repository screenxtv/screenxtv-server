RailsXServer::Application.routes.draw do
  resources :screens

  root to:'index#index'
  match 'doc/howto', to:'index#howto',as:'doc_howto'
  match 'doc/team', to:'index#team',as:'doc_team'
  match 'screen_notify/:url', to:'screens#notify'
  match 'screens/notify/:url', to:'screens#notify'
  match 'screens/authenticate/:url',to:'screens#authenticate'
  match 'screens/post/:url', to:'screens#post',via:'post'
  match 'screens/status/:url(/:key)',to:'screens#status'

  match 'screens.:format',to:'screens#index'

  match 'embed/:url', to:'screens#show_embed'
  match 'screens/post/:room/:id', to:'screens#post', via:'post'
  match 'screens/show/:url', to:'screens#show'
  match 'private/:url', to: 'screens#show_private'

  match 'users/authenticate/:url', to:'users#authenticate'
  match 'screens/authenticate', to:'users#authenticate'
  match 'users/sign_in', to:'users#sign_in'
  match 'users/sign_up', to:'users#sign_up'
  match 'users/sign_out', to:'users#sign_out', via:'delete'
  match 'users/index', to:'users#index'
  match 'users/edit', to:'users#edit'
  match 'users/update', to:'users#update', via:'post'
  match 'users/create_screen', to:'users#create_screen', via:'post'
  match 'users/destroy_screen', to:'users#destroy_screen', via:'post'
  match 'users/change_screen', to:'users#change_screen', via:'post'
  match 'users/show/:name', to:'users#show'

  match 'oauth/switch',to:'oauth#switch', via:'post'
  match 'oauth/disconnect', to:'oauth#disconnect', via:'post'
  match 'auth/:provider/popup' => 'oauth#auth_popup'
  match 'oauth/:provider/callback' => 'oauth#callback'
  match 'auth/:provider/callback' => 'oauth#callback'

  match ':url', to:'screens#show'

end
