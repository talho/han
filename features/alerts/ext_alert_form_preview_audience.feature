Feature: Alert Preview Audience Calculation
  In order to prevent accidentally-huge audiences
  As an alerter
  I can see an accurate total audience size on the Alert Preview page.

  Background:
    Given the following entities exists:
      | Role         | Health Alert and Communications Coordinator | han |
      | Role         | Epidemiologist                              | han |
      | Role         | Phantom                                     | han |
      | Role         | Populous                                    | han |
      | Role         | Masses                                      | han |
    And Federal is the parent jurisdiction of:
      | Texas |
    And Texas is the parent jurisdiction of:
      | Region 1 | Region 2 |
    And Region 1 is the parent jurisdiction of:
      | Tarrant County | Dallas County |
    And Region 2 is the parent jurisdiction of:
      | Potter County |
    And the following users exist:
      | Fed Hacc        | fed.hacc@example.com    | Health Alert and Communications Coordinator | Federal        | han |
      | Tex Hacc        | tex.hacc@example.com    | Health Alert and Communications Coordinator | Texas          | han |
      | Dal Hacc        | dal.hacc@example.com    | Health Alert and Communications Coordinator | Dallas County  | han |
      | Dal Epid        | dal.epid@example.com    | Epidemiologist                              | Dallas County  | han |
      | Tar Hacc        | tar.hacc@example.com    | Health Alert and Communications Coordinator | Tarrant County | han |
      | Tar Epid        | tar.epid@example.com    | Epidemiologist                              | Tarrant County | han |
      | Pot Hacc        | pot.hacc@example.com    | Health Alert and Communications Coordinator | Potter County  | han |
      | Pot Epid        | pot.epid@example.com    | Epidemiologist                              | Potter County  | han |
    And the role "Health Alert and Communications Coordinator" is an alerter

  Scenario: A non-cross-jurisdictional alert is sent within a single jurisdiction
    Given I am logged in as "dal.hacc@example.com"
    And I am allowed to send alerts
    And I navigate to "Apps > HAN > Send an Alert"
    When I fill in the following:
      | Title                 | H1N1 SNS push packs to be delivered tomorrow |
      | Message               | There is a Chicken pox outbreak in the area  |
      | Short Message         | Chicken pox outbreak                         |
    And I check "E-mail"
    And I check "Disable Cross-Jurisdictional Alerting"
    And I select "Dallas County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    Then I should have the "Recipients" breadcrumb selected
    And I select the following in the audience panel:
      | name           | type         | state    |
      | Dallas County  | Jurisdiction | Region 1 |
    And I click breadCrumbItem "Preview"
    Then I should see "2" within ".recipient_count"

  Scenario: A cross-jurisdictional alert is sent to a sibling jurisdiction
    Given I am logged in as "dal.hacc@example.com"
    And I am allowed to send alerts
    And I navigate to "Apps > HAN > Send an Alert"
    When I fill in the following:
      | Title                 | H1N1 SNS push packs to be delivered tomorrow |
      | Message               | There is a Chicken pox outbreak in the area  |
      | Short Message         | Chicken pox outbreak                         |
    And I check "E-mail"
    And I select "Dallas County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    Then I should have the "Recipients" breadcrumb selected
    And I select the following in the audience panel:
      | name           | type         | state    |
      | Tarrant County | Jurisdiction | Region 1 |
    And I click breadCrumbItem "Preview"
    Then I should see "3" within ".recipient_count"

  Scenario: A cross-jurisdictional alert is sent to a cousin jurisdiction
    Given I am logged in as "dal.hacc@example.com"
    And I am allowed to send alerts
    And I navigate to "App > HAN > Send an Alert"
    When I fill in the following:
      | Title                 | H1N1 SNS push packs to be delivered tomorrow |
      | Message               | There is a Chicken pox outbreak in the area  |
      | Short Message         | Chicken pox outbreak                         |
    And I check "E-mail"
    And I select "Dallas County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    Then I should have the "Recipients" breadcrumb selected
    And I select the following in the audience panel:
      | name           | type         | state    |
      | Tarrant County | Jurisdiction | Region 1 |
      | Potter County  | Jurisdiction | Region 2 |
    And I click breadCrumbItem "Preview"
    Then I should see "6" within ".recipient_count"

  Scenario: A cross-jurisdictional alert is sent to a role
    Given I am logged in as "dal.hacc@example.com"
    And I wait for 0.1 seconds
    And I am allowed to send alerts
    And I navigate to "Apps > HAN > Send an Alert"
    When I fill in the following:
      | Title                 | H1N1 SNS push packs to be delivered tomorrow |
      | Message               | There is a Chicken pox outbreak in the area  |
      | Short Message         | Chicken pox outbreak                         |
    And I check "E-mail"
    And I select "Dallas County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    Then I should have the "Recipients" breadcrumb selected
    And I select the following in the audience panel:
      | name                | type         |
      | Han: Epidemiologist | Role         |
    And I click breadCrumbItem "Preview"
    Then I should see "7" within ".recipient_count"

  Scenario: An alert is sent to nobody
    Given I am logged in as "dal.hacc@example.com"
    And I am allowed to send alerts
    And I navigate to "Apps > HAN > Send an Alert"
    When I fill in the following:
      | Title                 | H1N1 SNS push packs to be delivered tomorrow |
      | Message               | There is a Chicken pox outbreak in the area  |
      | Short Message         | Chicken pox outbreak                         |
    And I check "E-mail"
    And I select "Dallas County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    Then I should have the "Recipients" breadcrumb selected
    And I select the following in the audience panel:
      | name                | type         |
      | Han: Phantom        | Role         |
    And I click breadCrumbItem "Preview"
    Then I should see "0" within ".recipient_count"

  Scenario: Audience greater than 100 should prompt for user confirmation before sending
    Given the following entities exists:
      | Role | Masses |
    And 50 users exist like
      | role         | Populous       |
      | application  | han            |
      | jurisdiction | Dallas County  |
    And 51 users exist like
      | role         | Masses         |
      | application  | han            |
      | jurisdiction | Dallas County  |
    And I am logged in as "dal.hacc@example.com"
    And I am allowed to send alerts
    And I navigate to "Apps > HAN > Send an Alert"
    When I fill in the following:
      | Title                 | H1N1 SNS push packs to be delivered tomorrow |
      | Message               | There is a Chicken pox outbreak in the area  |
      | Short Message         | Chicken pox outbreak                         |
    And I check "E-mail"
    And I select "Dallas County" from ext combo "Jurisdiction"
    When I click breadCrumbItem "Recipients"
    Then I should have the "Recipients" breadcrumb selected
    And I select the following in the audience panel:
      | name                | type         |
      | Han: Populous       | Role         |
      | Han: Masses         | Role         |
    And I click breadCrumbItem "Preview"
    Then I should see "101" within ".recipient_count"
    When I press "Send Alert"
    Then I should see "ATTENTION"
    When I press "Cancel"
    Then I should have the "Recipients" breadcrumb selected
    When I select the following in the audience panel:
      # deselect 1/2 of the users
      | name                | type         |
      | Han: Populous       | Role         |
    And I click breadCrumbItem "Preview"
    Then I should see "51" within ".recipient_count"
    When I press "Send Alert"
    Then I should see "Alert Log and Reporting"
    And I should see "H1N1 SNS push packs"

  Scenario: Malicious user cannot get recipient counts
    Given I am logged in as "pot.epid@example.com"
    When I override alert
    And I maliciously post data to "/han_alerts/calculate_recipient_count.json"
      | from_jurisdiction_id | 1 |
      | jurisdiction_ids[]   | 2 |
    Then I should see "You do not have permission" within the alert box

  Scenario: Malicious anon cannot get recipient counts
    Given I am on the login page
    When I override alert
    When I maliciously post data to "/han_alerts/calculate_recipient_count.json"
      | from_jurisdiction_id | 1 |
      | jurisdiction_ids[]   | 2 |
    Then I should see "<title>TXPhin: sessions/new</title>" within the alert box