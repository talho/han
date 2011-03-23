When /^I force open the HAN alert cancellation tab$/ do
  al = Alert.find(:all).first
  force_open_tab('Create an Alert Cancellation', '', "{title: 'Create an Alert Cancellation', url: 'alerts/#{al.id}/edit?_action=cancel', mode: 'update', initializer: 'Talho.SendAlert', alertId: #{al.id}}")
end

When /^I force open the HAN alert update tab$/ do
  al = Alert.find(:all).first
  force_open_tab('Create an Alert Update', '', "{title: 'Create an Alert Update', url: 'alerts/#{al.id}/edit?_action=update', mode: 'update', initializer: 'Talho.SendAlert', alertId: #{al.id}}")
end