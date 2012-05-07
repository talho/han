
Openphin::Application.routes.draw do
  resources :han_alerts do
      member do
        get :acknowledge
        put :acknowledge
      end
  end
  match "/han_alerts/index/upload", :to => "han_alerts#upload", :as => 'upload', :via => [:get, :post]
  match "/han_alerts/new/playback.wav", :to => "han_alerts#playback", :as => 'playback', :via => [:get]
  match "/han_alerts/calculate_recipient_count.:format", :to => "han_alerts#calculate_recipient_count"
  match "/han_alerts/:id/emailack/:call_down_response", :to => "han_alerts#acknowledge", :email => "1", :as => 'email_acknowledge_alert'
  match "/han_alerts/:id/acknowledge(.:format)", :to => "application#options", :via => [:options]
  match "/han_alerts/:id/acknowledge/:token(.:format)", :to => "han_alerts#token_acknowledge", :as => 'token_acknowledge_alert'
end
