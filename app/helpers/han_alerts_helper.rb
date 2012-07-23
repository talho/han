module HanAlertsHelper

  def acknowledge_alert_button(alert, options = {:response => "1"})
    if alert.ask_for_acknowledgement?(current_user)
      button_to 'Acknowledge', update_alert_path(alert.id, options), :method => :put
    end
  end
end

# form.object.jurisdiction_ids.include?(item.id)
