Feature: User Registration
  As a visitor to the Bemeda Personal platform
  I want to register as either a job seeker or employer
  So that I can access personalized features and services

  Background:
    Given the application is running

  @bdd @registration
  Scenario: Job seeker completes two-step registration
    Given I visit the registration page
    When I select "job_seeker" as user type
    And I fill in personal information on step 1
    And I click "Next" button
    Then I should see step 2 of registration
    When I fill in work information on step 2
    And I accept the terms and conditions
    And I click "Create account" button
    Then I should be registered successfully
    And I should receive a confirmation email

  @bdd @registration
  Scenario: Employer completes single-step registration
    Given I visit the registration page
    When I select "employer" as user type
    And I fill in employer registration details
    And I accept the terms and conditions
    And I click "Create account" button
    Then I should be registered successfully
    And I should receive a confirmation email

  @bdd @registration
  Scenario: Registration fails with invalid email
    Given I visit the registration page
    When I select "job_seeker" as user type
    And I fill in personal information with invalid email
    And I click "Next" button
    Then I should see error message "must have the @ sign and no spaces"

  @bdd @registration
  Scenario: Registration requires email confirmation
    Given I have registered as a job seeker
    When I check my confirmation email
    Then I should see a confirmation link
