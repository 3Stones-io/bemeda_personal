@bdd
Feature: Job Posting and Application Review
  As an employer
  I want to post jobs and review applications
  So that I can find qualified healthcare professionals

  Background:
    Given I am logged in as "employer"
    And I have a company profile

  @smoke @employer
  Scenario: Create new job posting
    When I visit the company jobs page
    And I click "Post New Job"
    And I fill in job title with "Senior ICU Nurse"
    And I fill in job location with "Zürich"
    And I fill in job description with "Looking for experienced nurse"
    And I click "Publish Job"
    Then I should see "Job posted successfully"
    And the job should be visible in job listings

  @smoke @employer
  Scenario: Review job applications
    Given my company has a job with 5 applications
    When I visit the company applicants page
    Then I should see 5 applications
    And each application should show applicant name

  @employer
  Scenario: Update application status
    Given my company has a job with 1 application
    And the application status is "pending"
    When I visit the application details
    And I change status to "interview"
    And I add note "Good candidate, schedule interview"
    And I click "Save"
    Then the status should be "interview"