@ext
Feature: Sending alerts to SMS devices

  In order to be notified of an alert
  As a user
  I want people to be able to send me alerts on my SMS device

  Background:
    Given the following users exist:
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator | Dallas County  | han |
      | Keith Gaddis    | keith.gaddis@example.com | Epidemiologist                              | Wise County    | han |
    And "Texas" is the parent jurisdiction of:
      | Dallas County |
      | Wise County   |
    And the role "Health Alert and Communications Coordinator" is an alerter
    And delayed jobs are processed

  Scenario: Sending alerts to SMS devices
    Given I am logged in as "keith.gaddis@example.com"
    When I navigate to "Keith Gaddis > Edit My Account"
    And I press "Add device"
    And I select "SMS" from ext combo "Device type"
    And I fill in "Address / Number" with "2105551212"
    And I press "Add"
    And I press "Apply Changes"
    And I sign out
    
    Given I am logged in as "john.smith@example.com"
    And I am allowed to send alerts
    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"

    When I fill in the ext alert defaults
    And I uncheck "E-mail"
    And I check "SMS"
    And I fill in "Caller ID" with "4114114111"
    And I select "Moderate" from ext combo "Severity"
    And I fill in "Short Message" with "Chicken pox outbreak short message"

    And I select the following alert audience:
      | name         | type |
      | Keith Gaddis | User |

    And I click breadCrumbItem "Preview"
    And I wait for the audience calculation to finish
    And I press "Send Alert"
    Then the "Alert Log and Reporting" tab should be open

    When delayed jobs are processed
    Then the following SMS calls should be made:
      | sms         | message                            |
      | 12105551212 | Chicken pox outbreak short message |