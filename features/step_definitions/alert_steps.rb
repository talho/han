Given "an alert with:" do |table|
  create_han_alert_with table.rows_hash
end

Given "a sent alert with:" do |table|
  alert = create_han_alert_with table.rows_hash
  step "delayed jobs are processed"
end

Given /^(\d+) (?:more alerts are|more alert is) sent to me$/ do |n|
  last_alert = current_user.recent_han_alerts.last
  n.to_i.times do |i|
    # always make these alerts happen after the last alert for the user
    alert = create_han_alert_with "people" => current_user.name, "created_at" => last_alert.created_at + 1.second
  end
end

Given "I've sent an alert with:" do |table|
  visit new_han_alert_path
      #And I follow "Send an Alert"
  step %{I select "Advanced" from "Acknowledge"}
  step %{delayed jobs are processed}
  fill_in_han_alert_form table
  step %{I press "Preview Message"}
  step %{I press "Send"}
#  visit new_alert_path
#  fill_in_han_alert_form table
#  click_button "Preview Message"
#  lambda { click_button "Send" }.should change(Alert, :count).by(1)
end

Given /^I've sent an acknowledge alert with:$/ do |table|
  visit new_han_alert_path
  fill_in_han_alert_form table
  select("Normal", :from => "alert_acknowledge")
  click_button "Preview Message"
  lambda { click_button "Send" }.should change(Alert, :count).by(1)
end


Given "\"$email_address\" has acknowledged the HAN alert \"$title\"" do |email_address, title|
  u = User.find_by_email(email_address)
  alert = HanAlert.find_by_title(title)
  aa = alert.alert_attempts(true).find_by_user_id(u.id)
  aa.acknowledge!
  1==1
end

When /I acknowledge the phone message for "([^"]*)"(?: with "([^"]*)")?$/ do |title, ack|
  u = current_user
  al = HanAlert.find_by_title(title)
  aa = al.alert_attempts.find_by_user_id(u)
  if aa.nil?
    aa = FactoryGirl.create(:alert_attempt, :alert => al, :user => u, :acknowledged_at => nil, :acknowledged_alert_device_type_id => AlertDeviceType.find_by_device("Device::PhoneDevice"))
    del = FactoryGirl.create(:delivery, :alert_attempt => aa, :device => u.devices.phone.first)
  end
  unless ack.nil?
    aa.acknowledge! :response => al.call_down_messages.key(ack)
  else
    aa.acknowledge! :response => 1
  end
end

Given "\"$email_address\" has not acknowledged the HAN alert \"$title\"" do |email_address, title|
  u = User.find_by_email(email_address)
  alert = HanAlert.find_by_title(title)
  aa = alert.alert_attempts(true).find_by_user_id(u.id)
  aa.update_attribute('acknowledged_at', nil)
end

Given /^"([^\"]*)" has acknowledged the HAN alert "([^\"]*)" with "([^\"]*)" (\d+) (minute|hour)s? later$/ do |email_address, title, message, num, units|
  u = User.find_by_email(email_address)
  alert = HanAlert.find_by_title(title)
  delta = units == "hour" ? num.to_i.hours.to_i : num.to_i.minutes.to_i
  aa = alert.alert_attempts(true).find_by_user_id(u.id)
  aa.created_at += (delta)
  aa.save
  aa.acknowledge! :response => alert.call_down_messages.key(message)
end

Given /^(\d*) random HAN alerts$/ do |count|
  srand count.to_i
  size=Jurisdiction.all.size
  count.to_i.times do
    j=Jurisdiction.find(rand(size)+1)
    FactoryGirl.create(:han_alert, :from_jurisdiction => j)
  end
end

Given /^(\d*) random HAN alerts in (.*)$/ do |count, jurisdiction|
  srand count.to_i
  jurisdiction = Jurisdiction.find_by_name(jurisdiction)
  size=jurisdiction.children.size
  count.to_i.times do
    j=jurisdiction.self_and_descendants[rand(size)]
    FactoryGirl.create(:han_alert, :from_jurisdiction => j)
  end
end

When /^PhinMS delivers the message: (.*)$/ do |filename|
  require 'edxl/message'
  xml = File.read("#{Rails.root.to_s}/spec/fixtures/#{filename}")
  if(Edxl::MessageContainer.parse(xml).distribution_type == "Ack")
    Edxl::AckMessage.parse(xml)
  else
    Edxl::Message.parse(xml)
  end
  step "delayed jobs are processed"
end

When /I fill out the alert form with:/ do |table|
  fill_in_han_alert_form table
end

When "I make changes to the HAN alert form with:" do |table|
  table.rows_hash.each do |label, value|
    fill_in_han_alert_field label, value
  end
end

When 'I click "$link" on "$title"' do |link, title|
  waiter do
    page.find(".han_alert", :text => /#{title}/).click_link link
  end
end

When /^I follow the acknowledge HAN alert link$/ do
  attempt = current_user.nil? ? AlertAttempt.last : current_user.alert_attempts.last
  visit update_alert_with_token_url(attempt.alert.id, attempt.token, :host => "#{page.driver.rack_server.host}:#{page.driver.rack_server.port}", :response => 1)
end

When 'I follow the acknowledge HAN alert link "$title"' do |title|
  attempt = current_user.nil? ? AlertAttempt.last : current_user.alert_attempts.last
  if title.blank?
    visit update_alert_with_token_url(attempt.alert.id, attempt.token, :host => "#{page.driver.rack_server.host}:#{page.driver.rack_server.port}", :response => 1)
  else
    response = attempt.alert.call_down_messages.key(title).to_i
    if current_user.nil?
      raise "Step not yet supported if no user is logged in"
    else
      visit update_alert_url(attempt.alert, :host => "#{page.driver.rack_server.host}:#{page.driver.rack_server.port}", :response => response)
    end
  end
end

When 'I send a message recording "$filename"' do |filename|
  File.new("#{Rails.root.to_s}/message_recordings/tmp/#{current_user.token}.wav","w").close
end

Then 'I should see a preview of the message' do
  page.should have_css('#preview')
end

Then 'I should see a preview of the message with:' do |table|
  table.rows_hash.each do |key, value|
    case key
      when /(Jurisdiction|Role|Organization|People)s?/
        value.split(',').each do |item|
          page.should have_css(".#{key.parameterize('_')}", :content => Regexp.new(Regexp.escape(item.strip)))
        end
      else
        page.should have_css(".#{key.parameterize('_')}", :content => Regexp.new(Regexp.escape(value)))
    end
  end
end

Then 'a foreign alert "$title" is sent to $name' do |title, name|
  step "delayed jobs are processed"
  cascade_alert = CascadeHanAlert.new(HanAlert.find_by_title(title))
  organization = Organization.find_by_name!(name)
  File.exist?(File.join(organization.phin_ms_queue, "#{cascade_alert.distribution_id}.edxl")).should be_true
end

Then 'no foreign alert "$title" is sent to $name' do |title, name|
  step "delayed jobs are processed"
  cascade_alert = CascadeHanAlert.new(HanAlert.find_by_title(title))
  organization = Organization.find_by_name!(name)
  File.exist?(File.join(organization.phin_ms_queue, "#{cascade_alert.distribution_id}.edxl")).should be_false
end

Then 'a HAN alert exists with:' do |table|
  attrs = table.rows_hash
  conditions = attrs['identifier'].blank? ? "" : "identifier = :identifier OR "
  conditions += attrs['message'].blank? ? "title = :title" : "(title = :title AND message = :message)"
  alert = HanAlert.first(:conditions => [conditions,{:identifier => attrs['identifier'], :title => attrs['title'], :message => attrs['message']}])
  attrs.each do |attr, value|
    case attr
    when 'from_jurisdiction'
      alert.from_jurisdiction.should == Jurisdiction.find_by_name!(value)
    when 'jurisdiction'
      alert.audiences.map(&:jurisdictions).flatten.should include(Jurisdiction.find_by_name!(value))
    when 'role'
      alert.audiences.map(&:roles).flatten.should include(Role.find_by_name(value))
    when 'from_organization'
      alert.from_organization.should == Organization.find_by_name!(value)
    when 'delivery_time'
      alert.delivery_time.should == value.to_i
    when 'sent_at'
      alert.sent_at.should be_within(1).of(Time.zone.parse(value))
    when 'acknowledge'
      alert.acknowledge.should == (value == "true" ? true : false)
    when 'acknowledged_at'
      alert.acknowledged_at.to_s.should == value
    when 'people'
      value.split(",").each do |user|
        first_name, last_name = user.split(" ")
        alert.recipients.should include(User.find_by_first_name_and_last_name(first_name, last_name))
      end
    when 'call_down_messages'
      alert.call_down_messages.values.include?(value).should be_true
    when 'not_cross_jurisdictional'
      alert.not_cross_jurisdictional.to_s.should == value
    when 'targets'
      value.split(",").each do |email|                                                                                                             
        alert.targets.map(&:users).flatten.map(&:email).include?(email.strip).should be_true
      end
    else
      alert.send(attr).should == value
    end
  end
end

Then 'an alert should not exist with:' do |table|
  attrs = table.rows_hash
  conditions = attrs['identifier'].blank? ? "" : "identifier = :identifier OR "
  conditions += attrs['message'].blank? ? "title = :title" : "(title = :title AND message = :message)"
  alert = HanAlert.first(:conditions => [conditions,{:identifier => attrs['identifier'], :title => attrs['title'], :message => attrs['message']}])
  if alert.nil?
    alert.should be_nil
  else
    attrs.each do |attr, value|
      case attr
        when 'people'
          value.split(",").each do |name|
            display_name = name.split(" ").join(" ")
            alert.audiences.map(&:users).flatten.collect(&:display_name).should_not include(display_name)
          end
        when 'targets'
          value.split(",").each do |email|
            alert.targets.map(&:users).flatten.map(&:email).include?(email.strip).should be_false
          end
        else
          alert.send(attr).should == value
      end
    end
  end
end

Then /^I should see (\d*) HAN alerts?$/ do |n|
  page.should have_css(".han_alert", :count => n.to_i)
  #response.should have_selector('.alert', :count => n.to_i)
end

Then /^I should see an alert titled "([^\"]*)"$/ do |title|
  page.should have_content(title)
end

Then /^I should not see an alert titled "([^\"]*)"$/ do |title|
  page.should have_no_content(title)
  #response.should_not have_tag('.alert .title', title)
end

Then /^I should see a ([^\"]*) alert titled "([^\"]*)"$/ do |severity, title|
  response.should have_tag(".alert .title .#{severity.downcase}", title)
end

Then /^I should see a contacted user "([^\"]*)" with a "([^\"]*)" device$/ do |email, device_type|
  response.should have_selector(".user") do |elm|
    is_good = true
    elm.css("tr").each do |tr|
      is_good = true
      begin
        tr.should have_selector(".email", :content => email)
      rescue
        is_good = false
      end

      begin
        tr.should have_selector(".device_type", :content => device_type)
      rescue
        is_good = false
      end

      break if is_good
    end
    is_good.should be_true
  end
end

Then /^I should not see a ([^\"]*) alert titled "([^\"]*)"$/ do |severity, title|
  response.should_not have_tag(".alert .title .#{severity.downcase}", title)
end

Then /^I can see the alert summary for "([^\"]*)"$/ do |title|
  alert = Alert.find_by_title!(title)
  page.has_css?("#" + dom_id(alert))
  #response.should have_tag('#?', dom_id(alert))
end

Then 'I should see an alert with the summary:' do |table|
  table.rows_hash.each do |field, value|
    page.should have_css(".han_alert .summary .#{field}", :content => value)
  end
end

Then 'I should see an alert with the detail:' do |table|
  table.rows_hash.each do |field, value|
    page.should have_css(".han_alert .details .#{field}", :content => value)
  end
end

Then 'the alert "$alert_id" should be acknowledged' do |alert_id|
  pending "This is very fragile and needs to be re-thought."
  alert = Alert.find_by_identifier(alert_id)
  Jurisdiction.federal.first.alert_attempts.find_by_alert_id(alert.id).deliveries.first.sys_acknowledged_at?.should be_true
end

Then /^I can see the alert for "([^\"]*)" is (\d*)\% acknowledged$/ do |title,percent|
  waiter do
    page.find('.progress', :text => percent)
  end.should_not be_nil
end

Then /^I can see the jurisdiction alert acknowledgement rate for "([^\"]*)" in "([^\"]*)" is (\d*)%$/ do |alert_name, jurisdiction_name, percentage|
  waiter do
    page.find(".jur_ackpct .jurisdiction", :text => jurisdiction_name)
  end.should_not be_nil

  waiter do
    page.find(".jur_ackpct .percentage", :text => percentage)
  end.should_not be_nil
end

Then /^I can see the device alert acknowledgement rate for "([^\"]*)" in "([^\"]*)" is (\d*)%$/ do |alert_name, device_type, percentage|
  waiter do
    page.find(".dev_ackpct .#{device_type} .percentage", :text => percentage)
  end.should_not be_nil
end

Then /^I can see the alert acknowledgement response rate for "([^\"]*)" in "([^\"]*)" is (\d*)%$/ do |alert_name, alert_response, percentage|
  alert = HanAlert.find_by_title(alert_name)
  num = alert.call_down_messages.index(alert_response)
  waiter do
    page.find(".response_ackpct #response#{num} .percentage", :text => percentage)
  end.should_not be_nil
end

Then /^I cannot see the device alert acknowledgement rate for "([^\"]*)" in "([^\"]*)"$/ do |alert_name, device_type|
  waiter do
    page.has_css?(".#{device_type}")
  end.should_not be_true
end

Then /^the alert should be acknowledged$/ do
  attempt = current_user.nil? ? AlertAttempt.last : current_user.alert_attempts.last
  attempt.acknowledged_at.to_i.should be_within(5000).of(Time.zone.now.to_i)
end

Then /^the latest alert should be acknowledged$/ do    # Same as above, but without the should_be_close
  attempt = current_user.nil? ? AlertAttempt.last : current_user.alert_attempts.last
end

Then /^the alert should be acknowledged with response number "([^\"]*)"$/ do |alert_response|
  attempt = current_user.nil? ? AlertAttempt.last : current_user.alert_attempts.last
  attempt.call_down_response.should == alert_response.to_i
end

Then /^the alert should not be acknowledged$/ do
  attempt = current_user.nil? ? AlertAttempt.last : current_user.alert_attempts.last
  attempt.acknowledged_at.should be_blank
end

Then /^the alert should be acknowledged at time "([^\"]*)"$/ do |time|
  attempt = current_user.nil? ? AlertAttempt.last : current_user.alert_attempts.last
  attempt.acknowledged_at.should_not be_nil
  attempt.acknowledged_at.to_s(:db).should == time.to_time.to_s(:db)
end

Then /^I have acknowledged the HAN alert for "([^\"]*)"$/ do |alert|
  HanAlert.find_by_title(alert).acknowledged_users.should include(current_user)
end

Then /^the cancelled alert "([^\"]*)" has an original alert "([^\"]*)"$/ do |alert_identifier, original_alert_identifier|
  alert = HanAlert.find_by_identifier(alert_identifier)
  original_alert = HanAlert.find_by_identifier(original_alert_identifier)
  alert.original_alert_id.should == original_alert.id
end

When /^a foreign alert "([^\"]*)" is sent$/ do |title|
  step "delayed jobs are processed"
  alert=HanAlert.find_by_title!(title)
  File.exist?(File.join(Agency[:phin_ms_path], "#{alert.distribution_id}.edxl")).should be_true

end
When /^no foreign alert "([^\"]*)" is sent$/ do |title|
  step "delayed jobs are processed"
  alert=HanAlert.find_by_title(title)
  File.exist?(File.join(Agency[:phin_ms_path],"#{alert.distribution_id}.edxl")).should_not be_true
end

When /^I re\-submit a cancellation for "([^\"]*)"$/ do |title|
  visit path_to("the cancel HAN alert page", title)
  #When "I press \"Preview Message\""
end

When /^I re\-submit an update for "([^\"]*)"$/ do |title|
  visit path_to("the update HAN alert page", title)
  #When "I press \"Preview Message\""
end

Then /^there should be an file "([^\"]*)" in the PhinMS queue$/ do | filename |
  filename[/-ACK\.edxl/] = ''
  CDCFileExchange.deliveries.index{|a| a.is_a?(String) ? a =~ Regexp.new(filename) : false}.should_not be_nil
end

Then /^the system acknowledgment for alert "([^\"]*)" should contain the following:$/ do |alert_identifier, table |
  i = CDCFileExchange.deliveries.index{|a| a.is_a?(String) ? a =~ Regexp.new(alert_identifier) : false}
  ack=CDCFileExchange.deliveries[i]
  ack_msg=Edxl::AckMessage.parse(ack, :no_delivery => true)
  table.raw.each do |row|
    ack_msg.send(row[0]).should == row[1]
  end
end

Then 'I should see the csv report for the alert titled "$title"' do |title|
  alert = Alert.find_by_title(title)

  alert.alert_attempts.each do |attempt|
    row = []
    if attempt.user.blank?
      row += ['','']
    else
      row += [attempt.user.display_name]
      row += [attempt.user.email]
    end
    row += [(attempt.acknowledged_alert_device_type.nil? ? "" : attempt.acknowledged_alert_device_type.device.constantize.display_name)]
    response.body.should include(row.join(','))
  end
end

Then /^the backgroundRB worker has queried and processed the SWN XML data "([^\"]*)"$/ do | filename |
  require 'vendor/plugins/backgroundrb/server/lib/bdrb_server_helper.rb'
  require 'vendor/plugins/backgroundrb/server/lib/meta_worker.rb'
  require 'lib/workers/query_swn_for_acknowledgments_worker.rb'
  QuerySwnForAcknowledgmentsWorker.new.query :filename => filename
end

Given /^(?:|I )am using (.+)$/ do |browser|
  case browser
    when "mobile safari"
      agent = "Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_1_2 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7D11 Safari/528.16"
      add_headers({'User-Agent' => agent})
    else
      # don't set a special User-Agent header
  end
end
