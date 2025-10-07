@bdd
Feature: Resume Management
  As a job seeker
  I want to manage my resume and professional information
  So that employers can evaluate my qualifications

  Background:
    Given I am logged in as "job_seeker"

  @resume
  Scenario: View my resume
    When I visit my resume page
    Then I should see resume sections for "Education"
    And I should see resume sections for "Work Experience"

  @resume
  Scenario: Add work experience
    Given I am on my resume page
    When I click "Add Work Experience"
    And I fill in experience title with "ICU Nurse"
    And I fill in experience company with "University Hospital"
    And I fill in experience start date with "2020-01-01"
    And I check "Current Position"
    And I fill in experience description with "Managed critical care"
    And I click "Save Experience"
    Then I should see "Work experience saved successfully"
    And the experience should appear in my resume

  @resume
  Scenario: Share resume with employer
    Given I have a complete resume
    And there is an employer viewing my application
    When the employer visits my public resume page
    Then they should see my complete resume
    But they should not see "Edit" button
