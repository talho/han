Feature: Sending sensitive alerts

  In order to not cause panic
  As a user
  I want to be able to keep sensitive alerts private
  
  Background: 
    Given the following entities exist:
      | Jurisdiction | Dallas County                               |
      | Jurisdiction | Wise County                                 |
      | Role         | Health Alert and Communications Coordinator |
      | Role         | Epidemiologist                              |
    And the following users exist:
      | John Smith   | john.smith@example.com   | Health Alert and Communications Coordinator | Dallas County |
      | Keith Gaddis | keith.gaddis@example.com | Epidemiologist                              | Wise County   |
    And the role "Health Alert and Communications Coordinator" is an alerter
    And delayed jobs are processed
    And I am logged in as "john.smith@example.com"
    And I am allowed to send alerts

  Scenario: Sending a sensitive email alert
    When I go to the new HAN alert page
    When I fill out the alert form with:
      | People | Keith Gaddis |
      | Title  | H1N1 SNS push packs to be delivered tomorrow |
      | Message | For more details, keep on reading... |
      | Severity | Moderate |
      | Status | Actual |
      | Acknowledge | None |
      | Communication methods | E-mail |
      | Sensitive | <checked> |

    And I press "Preview Message"
    Then I should see a preview of the message
      
    When I press "Send this Alert"
    Then I should see "Successfully sent the alert"
    And I should be on the HAN alert log
    And the following users should receive the HAN alert email:
      | People        | keith.gaddis@example.com |
      | subject       | Health Alert "H1N1 SNS push packs to be delivered tomorrow" |
      | body contains | Sensitive: use secure means of retrieval |
      | body does not contain | Title: H1N1 SNS push packs to be delivered tomorrow |
      | body does not contain | For more details, keep on reading... |
