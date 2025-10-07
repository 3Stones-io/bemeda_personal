@bdd @company_profile
Feature: Company Profile Management
  As an employer
  I want to manage my company profile information
  So that job seekers can learn about my organization

  Background:
    Given I am logged in as "employer"
    And I have a company profile

  @company_profile
  Scenario: View company dashboard
    When I visit the company dashboard
    Then I should see the company name
    And I should see the company description
    And I should see the company location

  @company_profile
  Scenario: Edit company information
    Given I am on the company dashboard
    When I click "Edit"
    And I fill in company name with "Updated Medical Center"
    And I fill in company description with "Leading healthcare provider"
    And I fill in company location with "Zurich, Switzerland"
    And I submit the company form
    Then I should see "Updated Medical Center"
    And I should see "Leading healthcare provider"

  @company_profile
  Scenario: Update company branding
    Given I am on the company edit page
    When I fill in company website with "https://newwebsite.com"
    And I fill in company phone with "+41445551234"
    And I submit the company form
    Then I should see "https://newwebsite.com"

  @company_profile
  Scenario: View public company profile as job seeker
    Given I am logged in as "job_seeker"
    And there is a company with public profile
    When I visit the public company page
    Then I should see the company name
    And I should see the company description
    But I should not see "Edit" button
