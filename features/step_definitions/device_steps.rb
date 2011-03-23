When /^"([^\"]*)" acknowledges the phone message for "([^\"]*)" with "([^\"]*)"$/ do |email, title, call_down_response|
  a = User.find_by_email(email).alert_attempts.find_by_alert_id(Alert.find_by_title(title).id)
  a.acknowledge!(:ack_response => a.alert.call_down_messages.index(call_down_response).to_i, :ack_device => "Device::PhoneDevice")
end