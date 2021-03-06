@ext
Feature: Alert Reports
  In order to fulfill grant reporting requirements
  As an alerter
  I can view csv reports of an alert

  Background:
    Given the following entities exists:
      | Jurisdiction | Dallas County                               |
      | Jurisdiction | Tarrant County                              |
      | Role         | Health Alert and Communications Coordinator |
      | Role         | Epidemiologist                              |
    And the following users exist:
      | John Smith      | john.smith@example.com  | Health Alert and Communications Coordinator | Dallas County  | han |
      | Brian Simms     | brian.simms@example.com | Epidemiologist                              | Tarrant County | han |
    And the role "Health Alert and Communications Coordinator" is an alerter
    And a sent alert with:
      | title             | Grant Sample                                                |
      | author            | John Smith                                                  |
      | from_jurisdiction | Dallas County                                               |
      | jurisdictions     | Dallas County, Tarrant County                               |
      | roles             | Health Alert and Communications Coordinator, Epidemiologist |
      | acknowledge       | Yes                                                         |
      | alert_response_1  | if you can respond within 15 minutes                        |
      | alert_response_2  | if you can respond within 30 minutes                        |
    And delayed jobs are processed

  Scenario: A non-alerter cannot view a report of an alert
    Given I am logged in as "brian.simms@example.com"
    When I am on the ext dashboard page
    And I navigate to "Apps > HAN > HAN Alerts"
    Then I should not be able to navigate to "HAN > Alert Log and Reporting"

  @clear_report_db
  Scenario: A alerter can report on an alert that has been acknowledged
    Given I am logged in as "brian.simms@example.com"
    And I am on the ext dashboard page
    When I navigate to "Apps > HAN > HAN Alerts"
    Then I can see the alert summary for "Grant Sample"
    When I click summary "Grant Sample"
    And I select "if you can respond within 30 minutes" from "Alert Response"
    And I press "Acknowledge"
    And I wait for the "Saving" mask to go away
    And I click han_alert "Grant Sample"
    And delayed jobs are processed

    When I am logged in as "john.smith@example.com"
    And I am on the ext dashboard page
    And I generate "RecipeInternal::HanAlertLogRecipe" report on "HanAlert" titled "Grant Sample"

    When I inspect the generated rendering
    Then I should see "Alert ID:" in the rendering
    And I should see "Title" in the rendering
    And I should see "Severity" in the rendering
    And I should see "Message" in the rendering
    And I should see "Status" in the rendering
    And I should see "Short Message" in the rendering
    And I should see "Acknowledge" in the rendering
    And I should see "Author" in the rendering
    And I should see "Sensitive" in the rendering
    And I should see "Created At" in the rendering
    And I should see "Jurisdictional" in the rendering
    And I should see "Audiences" in the rendering
    And I should see "Jurisdictions" in the rendering
    And I should see "Roles" in the rendering
    And I should see "People" in the rendering
    And I should see "Acknowledgements" in the rendering
    And I should see "Name" in the rendering
    And I should see "Email Address" in the rendering
    And I should see "Acknowledged with Device" in the rendering
    And I should see "Alert Response" in the rendering
    And I should see "Report Generated on" in the rendering
    And I should see "UTC for John Smith" in the rendering
    And I should not see "No Acknowledgements Found" in the rendering

    When I inspect the generated pdf
    Then I should see "Alert ID:" in the pdf
    And I should not see "No Acknowledgements Found" in the pdf
    And I should see "UTC for John Smith" in the rendering

    When I inspect the generated csv
    Then I should see "display_name" in the csv
    And I should see "email" in the csv
    And I should see "device_type" in the csv
    And I should see "response" in the csv
    And I should see "time" in the csv
    And I should see "Brian Simms" in the csv
    And I should see "brian.simms@example.com" in the csv
    And I should see "Console" in the csv
    And I should see "if you can respond within 30 minutes" in the csv
    And I should see "UTC" in the csv
