Feature: Audit Log
  In order to keep tabs on the system and spot issues more effectively
  As a site administrator
  I want to be able to track every create, update, and destroy on the system

  Background:
    Given the following entities exist:
      | Jurisdiction | Texas                                       |
      | Role         | Boss                                        |
    And Texas is the parent jurisdiction of:
     | Region 1 |
    And Region 1 is the parent jurisdiction of:
     | Dallas County, Travis County |
    And the following users exist:
      | Jane Smith | janesmith@example.com | Boss       | Dallas County |
      | Bill Smith | billsmith@example.com | SysAdmin   | Texas         |

  Scenario: Audit log for Han Alert model
    Given I am logged in as "billsmith@example.com"
    And I navigate to the ext dashboard page
    And a sent alert with:
      | title                 | TEST ALERT              |
      | message               | TEST PLEASE DISREGARD   |
      | acknowledge           | No                      |
      | from_jurisdiction     | Dallas County           |
      | communication methods | Email                   |
      | people                | Jane Smith              |
    And I navigate to "Admin > Audit Log"
    Then the "Audit Log" tab should be open
    And I click model-selector-list-item "Han Alerts"
    Then I should see 2 rows in grid "grid-version-results"
    And I click model-selector-list-item "Han Alerts"
    And I click model-selector-list-item "Alert Attempts"
    Then I should see 4 rows in grid "grid-version-results"
    And I click model-selector-list-item "Alert Attempts"
    And I click model-selector-list-item "Audiences"
    Then I should see 1 rows in grid "grid-version-results"
    And I click model-selector-list-item "Audiences"
    And I click model-selector-list-item "Deliveries"
    Then I should see 2 rows in grid "grid-version-results"
    And I click model-selector-list-item "Deliveries"
    And I click model-selector-list-item "Targets"
    Then I should see 2 rows in grid "grid-version-results"
    And I click model-selector-list-item "Targets"
    And I click model-selector-list-item "Alert Ack Logs"
    Then I should see 8 rows in grid "grid-version-results"