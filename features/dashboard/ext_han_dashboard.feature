@ext
Feature: Viewing the dashboard

    Background:
        Given the following entities exists:
          | Jurisdiction  | Dallas County         |     |
          | Jurisdiction  | Tarrant County        |     |
          | Jurisdiction  | Texas                 |     |
          | Role          | Public                |     |
          | Role          | Health Officer        | han |
          | Role          | Immunization Director | han |
          | Role          | HAN Coordinator       | han |
        And the role "HAN Coordinator" is an alerter
        And Texas is the parent jurisdiction of:
          | Dallas County | Tarrant County |
        And Dallas County has the following administrators:
          | Bob Jones      | admin1@dallascounty.com   | han |
          | Quincy Jones   | admin2@dallascounty.com   | han |
        And Tarrant County has the following administrators:
          | TarrantCounty Admin  | admin@tarrantcounty.com      |
        And Texas has the following administrators:
          | Zach Dennis   | admin@texas.com      |
        
    Scenario: Dashboard should show only the panels each user has access to

    Scenario: Dashboard should show the user navigation
    Given the following users exist:
      | John Smith      | john.smith@example.com   | Public | Dallas County | han |
    And I am logged in as "john.smith@example.com"
    When I navigate to "Apps > HAN"
    Then I should see the following ext menu items:
      | name |
      | HAN Alerts |
    And I should not see the following ext menu items:
      | name                    |
      | Send an Alert           |
      | Alert Log and Reporting |

    Scenario: Dashboard should show the alerter navigation
    Given the following users exist:
      | John Smith      | john.smith@example.com   | Public | Dallas County | han |
      And "admin1@texas.com" has approved the "HAN Coordinator" role in "Dallas County" for "john.smith@example.com"
    And I am logged in as "john.smith@example.com"
      When I navigate to "Apps > HAN"
      Then I should see the following ext menu items:
      | name                    |
      | HAN Alerts                |
      | Send an Alert           |
      | Alert Log and Reporting |

    Scenario: Dashboard should show the admin navigation
    And I am logged in as "admin1@dallascounty.com"
      When I navigate to "Apps > HAN"
      Then I should see the following ext menu items:
      | name |
      | HAN Alerts |
    And I should not see the following ext menu items:
      | name                    |
      | Send an Alert           |
      | Alert Log and Reporting |

    Scenario: Dashboard should show the admin alerter navigation
    And "admin1@texas.com" has approved the "HAN Coordinator" role in "Dallas County" for "admin1@dallascounty.com"
    And I am logged in as "admin1@dallascounty.com"
      When I navigate to "Apps > HAN"
      Then I should see the following ext menu items:
      | name                    |
      | HAN Alerts              |
      | Send an Alert           |
      | Alert Log and Reporting |
    