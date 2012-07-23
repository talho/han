
Openphin::Application.routes.draw do
  resources :han_alerts do
      collection do
        get :recent
      end
  end
  # han unique
  match "/han_alerts/index/upload", :to => "han_alerts#upload", :as => 'upload', :via => [:get, :post]
  match "/han_alerts/new/playback.wav", :to => "han_alerts#playback", :as => 'playback', :via => [:get]
  match "/han_alerts/calculate_recipient_count.:format", :to => "han_alerts#calculate_recipient_count"
end
