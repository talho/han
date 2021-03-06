@ext
Feature: Acknowledging an alert

  Background:
    Given the following users exist:
      | John Smith   | john.smith@example.com   | Health Alert and Communications Coordinator | Dallas County | han |
      | Keith Gaddis | keith.gaddis@example.com | Epidemiologist                              | Wise County   | han |
    And "Texas" is the parent jurisdiction of:
      | Dallas County |
      | Wise County   |
    And the role "Health Alert and Communications Coordinator" is an alerter
    And delayed jobs are processed

  Scenario: Acknowledging an alert through an email with signing in
    Given I am logged in as "john.smith@example.com"
    And I am allowed to send alerts
    And a sent alert with:
      | title                 | H1N1 SNS push packs to be delivered tomorrow |
      | message               | For more details, keep on reading...         |
      | severity              | Moderate                                     |
      | status                | Actual                                       |
      | acknowledge           | Yes                                          |
      | from_jurisdiction     | Dallas County                                |
      | communication methods | Email                                        |
      | people                | Keith Gaddis                                 |
      | jurisdictions         | Dallas County                                |
    Then the following users should receive the HAN alert email:
      | People        | keith.gaddis@example.com                                    |
      | subject       | Health Alert "H1N1 SNS push packs to be delivered tomorrow" |
      | body contains alert acknowledgment link | |

    When I sign out
    And I log in as "keith.gaddis@example.com"
    And I follow the acknowledge HAN alert link
    Then I should see "Successfully acknowledged alert: H1N1 SNS push packs to be delivered tomorrow"
    And the alert should be acknowledged

  Scenario: Acknowledging an alert through an email without signing in
    Given I am logged in as "john.smith@example.com"
    And I am allowed to send alerts
    And a sent alert with:
      | title                 | H1N1 SNS push packs to be delivered tomorrow |
      | message               | For more details, keep on reading...         |
      | severity              | Moderate                                     |
      | status                | Actual                                       |
      | acknowledge           | Yes                                          |
      | from_jurisdiction     | Dallas County                                |
      | communication methods | Email                                        |
      | people                | Keith Gaddis                                 |

    Then the following users should receive the HAN alert email:
      | People        | keith.gaddis@example.com                                    |
      | subject       | Health Alert "H1N1 SNS push packs to be delivered tomorrow" |
      | body contains alert acknowledgment link | |

    When I sign out
    And I follow the acknowledge HAN alert link
    Then I should see "Successfully acknowledged alert: H1N1 SNS push packs to be delivered tomorrow"
    And the alert should be acknowledged

  Scenario: A user cannot acknowledge an sensitive alert through an email without signing in
    Given I am logged in as "john.smith@example.com"
    And I am allowed to send alerts
    Given a sent alert with:
      | title                 | H1N1 SNS push packs to be delivered tomorrow |
      | message               | For more details, keep on reading...         |
      | severity              | Moderate                                     |
      | status                | Actual                                       |
      | acknowledge           | Yes                                          |
      | sensitive             | true                                         |
      | from_jurisdiction     | Dallas County                                |
      | communication methods | Email                                        |
      | people                | Keith Gaddis                                 |

    When delayed jobs are processed
    And the following users should receive the HAN alert email:
      | People        | keith.gaddis@example.com |
      | subject       | Health Alert "H1N1 SNS push packs to be delivered tomorrow" |
      | body does not contain alert acknowledgment link | |

    When I sign out
    And I follow the acknowledge HAN alert link
    Then I should see "you do not have access to it"
    And the alert should not be acknowledged

  Scenario: Acknowledging an alert through phone
    Given keith.gaddis@example.com has the following devices:
      | phone | 2105551212 |
    And I am logged in as "john.smith@example.com"
    And I am allowed to send alerts
    And a sent alert with:
      | title                 | H1N1 SNS push packs to be delivered tomorrow |
      | message               | There is a Chicken pox outbreak in the area  |
      | short_message         | Chicken pox outbreak                         |
      | severity              | Moderate                                     |
      | status                | Actual                                       |
      | acknowledge           | Yes                                          |
      | sensitive             | true                                         |
      | from_jurisdiction     | Dallas County                                |
      | communication methods | Phone                                        |
      | caller_id             | 4114114111                                   |
      | people                | Keith Gaddis                                 |

    And delayed jobs are processed
    Then the following phone calls should be made:
      | phone      | message                                                                                           |
      | 2105551212 | The following is an alert from the Texas Public Health Information Network.  There is a Chicken pox outbreak in the area |

    And I log in as "keith.gaddis@example.com"
    When I acknowledge the phone message for "H1N1 SNS push packs to be delivered tomorrow"
    And delayed jobs are processed

    When I navigate to the ext dashboard page
    And I wait for the "Loading" mask to go away
    And I navigate to "Apps > HAN > HAN Alerts"
    Then I can see the alert summary for "H1N1 SNS push packs to be delivered tomorrow"
    And I click han_alert "H1N1 SNS push packs to be delivered tomorrow"
    And I should not see an "Acknowledge" button
    But I should see "Acknowledge: Yes"
    # end legacy code: replace when acknowledgement is implemented

  Scenario: Acknowledging an alert through an email with signing in and call downs
    Given I am logged in as "john.smith@example.com"
    And I am allowed to send alerts
    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"
    And I fill in the ext alert defaults
    And I select "Advanced" from ext combo "Acknowledge"
    # add a 3rd response box
    And I press "+ Add another response"
    When I fill in the following:
      | Short Message    | Chicken pox outbreak                         |
      | Alert Response 1 | if you can call back within 15 minutes       |
      | Alert Response 2 | if you can call back within 30 minutes       |
      | Alert Response 3 | if you can call back within 45 minutes       |

    And I select the following alert audience:
      | name         | type |
      | Keith Gaddis | User |

    And I click breadCrumbItem "Preview"
    And I wait for the audience calculation to finish
    And I press "Send Alert"
    Then the "Alert Log and Reporting" tab should be open

    And the following users should receive the HAN alert email:
      | People        | keith.gaddis@example.com |

    And I am logged in as "keith.gaddis@example.com"
    And I follow the acknowledge HAN alert link "if you can call back within 30 minutes"
    Then I should see "Successfully acknowledged alert: H1N1 SNS push packs to be delivered tomorrow"
    And the alert should be acknowledged

    And I am logged in as "keith.gaddis@example.com"
    When I navigate to "Apps > HAN > HAN Alerts"
    Then I can see the alert summary for "H1N1 SNS push packs to be delivered tomorrow"
    And I should see "Acknowledge: if you can call back within 30 minutes"

    #### make sure the double-ack error works
    And I follow the acknowledge HAN alert link "if you can call back within 30 minutes"
    Then I should see "You may have already acknowledged the alert"
    # end legacy code: replace when acknowledgement is implemented

  Scenario: Acknowledging an alert through phone with call downs
    Given keith.gaddis@example.com has the following devices:
      | phone | 2105551212 |
    And I log in as "john.smith@example.com"
    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"

    When I fill in the ext alert defaults
    And I select "Advanced" from ext combo "Acknowledge"
    When I fill in the following:
      | Short Message    | Chicken pox outbreak                         |
      | Alert Response 1 | if you can call back within 15 minutes       |
      | Alert Response 2 | if you can call back within 30 minutes       |
    And I uncheck "E-mail"
    And I select "Moderate" from ext combo "Severity"
    And I check "Phone"
    And I fill in "Caller ID" with "4114114111"
    And I select the following alert audience:
      | name         | type |
      | Keith Gaddis | User |
    And I click breadCrumbItem "Preview"
    And I wait for the audience calculation to finish
    And I press "Send Alert"
    Then the "Alert Log and Reporting" tab should be open
    And I sign out

    When delayed jobs are processed
    Then the following phone calls should be made:
      | phone      | message                                                                                           |
      | 2105551212 | The following is an alert from the Texas Public Health Information Network.  There is a Chicken pox outbreak in the area |

    And I log in as "keith.gaddis@example.com"
    When I acknowledge the phone message for "H1N1 SNS push packs to be delivered tomorrow" with "if you can call back within 15 minutes"
    And delayed jobs are processed
    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > HAN Alerts"
    Then I click han_alert "H1N1 SNS push packs to be delivered tomorrow"
    And I should not see an "Acknowledge" button
    But I should see "Acknowledge: if you can call back within 15 minutes"

