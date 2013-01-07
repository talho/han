Then /^I should see "(.*)" as a from jurisdiction option$/ do |name|
  jurisdiction = Jurisdiction.find_by_name!(name)
  assert page.find("select#han_alert_from_jurisdiction_id option[@value=\"#{jurisdiction.id.to_s}\"]").nil? == false
end

Then /^I should not see "(.*)" as a from jurisdiction option$/ do |name|
  jurisdiction = Jurisdiction.find_by_name!(name)
  begin
    waiter do
      begin
        page.find("select#han_alert_from_jurisdiction_id option[@value=\"#{jurisdiction.id.to_s}\"]").nil?
        assert false
      rescue Capybara::ElementNotFound
      end
    end
  rescue Capybara::TimeoutError
    assert true
  end
end
