
Openphin::Application.routes.draw do
  resources :han_alerts, :only => [:index,:create,:new,:edit] do
      collection do
        get :recent
      end
  end
  match "/han_alerts/index/upload" => "han_alerts#upload", :as => :upload, :method => [:get, :post]
  match "/han_alerts/new/playback.wav" => "han_alerts#playback", :as => :playback, :method => [:get]
  match "/han_alerts/calculate_recipient_count.:format", :to => "han_alerts#calculate_recipient_count"
end
