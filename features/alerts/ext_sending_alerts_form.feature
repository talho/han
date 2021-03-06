Feature: Sending alerts form

  In order to ensure only accessible information is displayed on the form
  As an admin
  Users should not be able to see certain information on the form

  Scenario: Send alert form should perform client side validation
    Given the following users exist:
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator | Dallas County | han |
    And Texas is the parent jurisdiction of:
      | Dallas County |
    And Texas is a state
    And the role "Health Alert and Communications Coordinator" is an alerter
    And I am logged in as "john.smith@example.com"
    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"

    When I click breadCrumbItem "Recipients"
    Then I should have the "Alert Details" breadcrumb selected
    And the following fields should be invalid:
      | Title                 |
      | Communication Methods |

    When I fill in "Title" with "This is a test title to pass validation"
    And I check "E-mail"
    And I check "SMS"
    And I select "Dallas County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    Then I should have the "Alert Details" breadcrumb selected
    And the following fields should be invalid:
      | Message       |
      | Short Message |
      | Caller ID     |

    When I fill in "Message" with "This is a test message to pass validation"
    And I fill in "Short Message" with "This is a test short message to pass validation"
    And I fill in "Caller ID" with "4114114111"
    When I click breadCrumbItem "Recipients"
    Then I should have the "Recipients" breadcrumb selected

    When I override alert
    And I click breadCrumbItem "Preview"
    Then I should see "Please select at least one user, jurisdiction, role, or group to send this alert to." within the alert box

    When I click breadCrumbItem "Alert Details"
    And I click breadCrumbItem "Preview"
    Then I should see "Please select at least one user, jurisdiction, role, or group to send this alert to." within the alert box
    And I should have the "Recipients" breadcrumb selected

    And I select the following in the audience panel:
      | name           | type         |
      | Dallas County  | Jurisdiction |
    And I click breadCrumbItem "Preview"
    Then I should have the "Preview" breadcrumb selected
    And I should see "This is a test title to pass validation"

  Scenario: Sending alerts form should not contain system roles
    Given there is an system only Admin role
    And the following users exist:
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator | Dallas County | han |
    And Texas is the parent jurisdiction of:
      | Dallas County |
    And Texas is a state
    And the role "Health Alert and Communications Coordinator" is an alerter
    And I am logged in as "john.smith@example.com"
    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"
    Then the "Send Alert" tab should be open
    When I fill in the following:
      | Title   | This is a test title to pass validation   |
      | Message | This is a test message to pass validation |
    And I check "E-mail"
    And I select "Dallas County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    Then I should have the "Recipients" breadcrumb selected
    When I click x-accordion-hd "Roles"
    Then I should not see "Admin"
    When I navigate to "John Smith > Sign Out"

  Scenario: User with one or more jurisdictions
    Given the following entities exists:
      | Jurisdiction | Dallas County  |
      | Jurisdiction | Potter County  |
      | Jurisdiction | Tarrant County |
    And the following users exist:
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator | Dallas County | han |
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator | Potter County | han |
    And Texas is the parent jurisdiction of:
      | Dallas County |
      | Potter County |
    And Texas is a state
    And the role "Health Alert and Communications Coordinator" is an alerter
    And I am logged in as "john.smith@example.com"

    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"
    When I open ext combo "Jurisdiction"
    Then I should see "Dallas County"
    Then I should see "Potter County"
    Then I should not see "Tarrant County"
    When I fill in the following:
      | Title        | H1N1 SNS push packs to be delivered tomorrow |
      | Message      | H1N1 SNS push packs to be delivered tomorrow |
    And I check "E-mail"
    And I select "Potter County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    And I select the following in the audience panel:
      | name           | type         |
      | Dallas County  | Jurisdiction |
    And I click breadCrumbItem "Preview"
    Then I should have the "Preview" breadcrumb selected
    And I wait for the audience calculation to finish
    When I press "Send Alert"
    Then the "Alert Log and Reporting" tab should be open
    And the "Send Alert" tab should not be open
    When delayed jobs are processed
    Then a HAN alert exists with:
      | from_jurisdiction | Potter County                                |
      | title             | H1N1 SNS push packs to be delivered tomorrow |

  Scenario: Sending alerts should display Federal jurisdiction as an option
    Given the following users exist:
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator | Dallas County | han |
    And Texas is the parent jurisdiction of:
      | Dallas County |
    And Texas is a state
    And the role "Health Alert and Communications Coordinator" is an alerter
    And I am logged in as "john.smith@example.com"
    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"
    When I fill in the following:
      | Title   | This is a test title to pass validation   |
      | Message | This is a test message to pass validation |
    And I check "E-mail"
    And I select "Dallas County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    Then I should see "Federal"

  Scenario: Sending alerts should show "Select all children" link for parent jurisdictions
    Given the following entities exist:
      | Jurisdiction | Texas         |
      | Jurisdiction | Dallas County |
    And Texas is the parent jurisdiction of:
      | Dallas County |
    And Texas is a state
    And the following users exist:
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator | Texas | han |
    And the role "Health Alert and Communications Coordinator" is an alerter
    And I am logged in as "john.smith@example.com"
    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"
    When I fill in the following:
      | Title   | This is a test title to pass validation   |
      | Message | This is a test message to pass validation |
    And I check "E-mail"
    And I select "Texas" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    And I click contextArrow ""
    Then I should see "Select All Sub-jurisdictions"
    Then I should see "Select No Sub-jurisdictions"

  Scenario: Sending alerts with call down
    Given the following entities exists:
      | Jurisdiction | Dallas County  |
      | Jurisdiction | Potter County  |
      | Jurisdiction | Tarrant County |
    And the following users exist:
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator | Dallas County | han |
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator | Potter County | han |
    And Texas is the parent jurisdiction of:
      | Dallas County |
      | Potter County |
    And Texas is a state
    And the role "Health Alert and Communications Coordinator" is an alerter
    And I am logged in as "john.smith@example.com"

    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"
    And I select "Potter County" from ext combo "Jurisdiction"
    And I select "Advanced" from ext combo "Acknowledge"
    # add a 3rd, 4th and 5th response box
    And I press "+ Add another response"
    And I press "+ Add another response"
    And I press "+ Add another response"
    And I fill in the following:
      | Title              | H1N1 SNS push packs to be delivered tomorrow |
      | Message            | Some body text                               |
      | Alert Response 1   | if you can respond within 15 minutes         |
      | Alert Response 2   | if you can respond within 30 minutes         |
      | Alert Response 3   | if you can respond within 1 hour             |
      | Alert Response 4   | if you can respond within 4 hour             |
      | Alert Response 5   | if you cannot respond                        |
    And I select "Test" from ext combo "Status"
    And I select "Minor" from ext combo "Severity"
    And I select "72 hours" from ext combo "Delivery Time"
    And I check "Phone"
    And I fill in "Caller ID" with "4114114111"

    When I click breadCrumbItem "Recipients"
    And I select the following in the audience panel:
      | name           | type         |
      | Dallas County  | Jurisdiction |
    And I click breadCrumbItem "Preview"
    And I wait for the audience calculation to finish
    And I press "Send Alert"
    Then the "Alert Log and Reporting" tab should be open
    And the "Send Alert" tab should not be open

    Then a HAN alert exists with:
      | from_jurisdiction   | Potter County                                |
      | title               | H1N1 SNS push packs to be delivered tomorrow |
      | call_down_messages  | if you can respond within 15 minutes         |
      | call_down_messages  | if you can respond within 30 minutes         |
      | call_down_messages  | if you can respond within 1 hour             |
      | call_down_messages  | if you can respond within 4 hours            |
      | call_down_messages  | if you cannot respond                        |
      | acknowledge         | true                                         |

  Scenario: Sending alerts to Organizations
    Given the following entities exist:
      | Jurisdiction | Texas          |
      | Organization | DSHS           |
    And Federal is the parent jurisdiction of:
      | Texas |
    And Texas is a state
    And the following users exist:
    # since we're doing this in the texas space and aren't selecting a jurisdiction, I'm going to use the default han coordinator role here.
      | John Smith      | john.smith@example.com   | Health Alert and Communications Coordinator  | Texas         | han |
      | Jane Smith      | jane.smith@example.com   | Health Officer                               | Texas         | han |
    And "jane.smith@example.com" is a member of the organization "DSHS"
    And the role "Health Alert and Communications Coordinator" is an alerter
    And I am logged in as "john.smith@example.com"

    When I navigate to the ext dashboard page
    And I navigate to "Apps > HAN > Send an Alert"

    And I fill in the following:
      | Title              | H1N1 SNS push packs to be delivered tomorrow |
      | Message            | Some body text                               |
    And I select "Texas" from ext combo "Jurisdiction" 
    And I check "Phone"
    And I fill in "Caller ID" with "4114114111"

    When I click breadCrumbItem "Recipients"
    And I select the following in the audience panel:
      | name  | type         |
      | DSHS  | Organization |
    And I click breadCrumbItem "Preview"

    And I expand ext panel "Alert Recipients (Primary Audience)"

    Then I should see the following audience breakdown
      | name       | type         |
      | DSHS       | Organization |
      | Jane Smith | Recipient    |
    And I wait for the audience calculation to finish
    When I press "Send Alert"
    Then the "Alert Log and Reporting" tab should be open
    And the "Send Alert" tab should not be open
    
    Then a HAN alert exists with:
      | from_jurisdiction | Texas                                        |
      | people            | Jane Smith                                   |
      | title             | H1N1 SNS push packs to be delivered tomorrow |

