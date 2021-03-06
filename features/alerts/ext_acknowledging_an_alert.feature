@ext
Feature: Acknowledging an alert

  In order to report that I read an alerts
  As a user
  I can acknowledge an alert

  Background:
    Given the following users exist:
      | Martin Fowler      | martin@example.com   | Health Alert and Communications Coordinator | Dallas County | han |
    And the role "Health Alert and Communications Coordinator" is an alerter
    And I am logged in as "martin@example.com"
    When I am on the ext dashboard page

  Scenario: A user acknowledging an alert via the HAN
    Given a sent alert with:
      | title             | Piggy Pox            |
      | message           | the world is on fire |
      | status            | Actual               |
      | severity          | Moderate             |
      | acknowledge       | Yes                  |
      | from_jurisdiction | Dallas County        |
      | jurisdictions     | Dallas County        |
    And I navigate to "Apps > HAN > HAN Alerts"
    Then I can see the alert summary for "Piggy Pox"
    When I click summary "Piggy Pox"
    And I press "Acknowledge"
    And I wait for 0.1 seconds
    And I wait for the "Saving" mask to go away
    When I click summary "Piggy Pox"
    Then I have acknowledged the HAN alert for "Piggy Pox"
    Then I should not see an "Acknowledge" button
    But I should see "Acknowledge: Yes"

  Scenario: A user acknowledges an alert with a call down response via the HAN
    And a sent alert with:
      | title             | Piggy Pox                            |
      | message           | the world is on fire                 |
      | status            | Actual                               |
      | severity          | Moderate                             |
      | acknowledge       | Yes                                  |
      | from_jurisdiction | Dallas County                        |
      | jurisdictions     | Dallas County                        |
      | alert_response_1  | if you can respond within 15 minutes |
      | alert_response_2  | if you can respond within 30 minutes |
      | alert_response_3  | if you can respond within 1 hour     |
      | alert_response_4  | if you can respond within 4 hours    |
      | alert_response_5  | if you cannot respond                |
    And I navigate to "Apps > HAN > HAN Alerts"
    Then I can see the alert summary for "Piggy Pox"
    When I click summary "Piggy Pox"
    When I select "if you can respond within 30 minutes" from "Alert Response"
    When I press "Acknowledge"
    And I wait for 0.1 seconds
    And I wait for the "Saving" mask to go away
    When I click han_alert "Piggy Pox"

    Then I have acknowledged the HAN alert for "Piggy Pox"
    Then I should not see an "Acknowledge" button
    And I should not see "Alert Response"
    But I should see "Acknowledge: if you can respond within 30 minutes"
    And the alert should be acknowledged
