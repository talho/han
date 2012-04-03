When /^"([^"]*)" acknowledges the phone message for "([^"]*)"(?: with "([^"]*))"?$/ do |email, title, call_down_response|
  a = User.find_by_email(email).alert_attempts.find_by_alert_id(Alert.find_by_title(title).id)
  if a.alert.call_down_messages["1"] == "Please press one to acknowledge this alert."
    a.acknowledge!(:ack_response => "1", :ack_device => "Device::PhoneDevice")
  else
    a.acknowledge!(:ack_response => a.alert.call_down_messages.index(call_down_response).to_i, :ack_device => "Device::PhoneDevice")
  end
end

Then '"$email" should not receive a HAN alert email' do |email|
  find_han_alert_email(email).should be_nil
end

Then '"$email" should not receive a HAN alert email via SWN' do |email|
  find_han_alert_email_via_SWN(email).should be_nil
end

Then /^"([^\"]*)" should receive the HAN alert email:$/ do |email_address, table|
  find_han_alert_email(email_address, table).should_not be_nil
end

Then /^"([^\"]*)" should receive the HAN alert email via SWN:$/ do |email_address, table|
  find_han_alert_email_via_SWN(email_address, table).should_not be_nil
end

Then /^the following users should receive the HAN alert email:$/ do |table|
  When "delayed jobs are processed"

  headers = table.headers
  recipients = if headers.first == "roles"
    jurisdiction_name, role_name = headers.last.split("/").map(&:strip)
    jurisdiction = Jurisdiction.find_by_name!(jurisdiction_name)
    jurisdiction.users.with_role(role_name)
  end

  recipients = headers.last.split(',').map{|u| User.find_by_email!(u.strip)} if headers.first == "People"

  email = YAML.load(IO.read(Rails.root.to_s+"/config/email.yml"))[Rails.env]
  recipients.each do |user|
    if email["alert"] == "SWN"
      Then %Q{"#{user.email}" should receive the HAN alert email via SWN:}, table
    else
      Then %Q{"#{user.email}" should receive the HAN alert email:}, table
    end
  end
end

Then "the following users should not receive any HAN alert emails" do |table|
  When "delayed jobs are processed"

  headers = table.headers
  recipients = if headers.first == "roles"
    jurisdiction_name, role_name = headers.last.split("/").map(&:strip)
    jurisdiction = Jurisdiction.find_by_name!(jurisdiction_name)
    jurisdiction.users.with_role(role_name)
  elsif headers.first == "emails"
    headers.last.split(',').map(&:strip).map{|m| User.find_by_email!(m)}
  end

  recipients.each do |user|
    Then %Q{"#{user.email}" should not receive a HAN alert email via SWN}
  end
end
