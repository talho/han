module HanAlertsHelper

  def acknowledge_alert_button(alert)
    if alert.ask_for_acknowledgement?(current_user)
      button_to 'Acknowledge', acknowledge_han_alert_path(alert.id), :method => :put
    end
  end
end

# form.object.jurisdiction_ids.include?(item.id)
