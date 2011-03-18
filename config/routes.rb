ActionController::Routing::Routes.draw do |map|
  map.resources :han_alerts, :member => {:acknowledge => [:get, :put]}
  map.upload "han_alerts/index/upload", :controller => "alerts", :action => "upload", :method => [:get, :post]
  map.playback "han_alerts/new/playback.wav", :controller => "han_alerts", :action => "playback", :method => [:get]
  map.connect "han_alerts/calculate_recipient_count.:format", :controller => "han_alerts", :action => "calculate_recipient_count"
  map.email_acknowledge_alert "han_alerts/:id/emailack/:call_down_response", :controller => "han_alerts", :action => "acknowledge", :email => "1"
  map.connect "han_alerts/:id/acknowledge.:format", :controller => "application", :action => "options", :conditions => {:method => [:options]}
  map.token_acknowledge_alert "han_alerts/:id/acknowledge/:token.:format", :controller => "han_alerts", :action => "token_acknowledge"
end
