@bdd
Feature: Job Application
  As a job seeker
  I want to apply for job postings
  So that I can find employment in the healthcare sector

  Background:
    Given the application is running

  @smoke @job_application
  Scenario: Successfully apply for a job
    Given I am logged in as "job_seeker"
    And there is a job posting titled "ICU Nurse"
    When I visit the job details page
    And I click "Apply Now"
    And I fill in "Cover Letter" with "I am very interested in this position"
    And I click "Submit Application"
    Then I should see "Application submitted successfully"
    And the application should be saved to the database

  @job_application
  Scenario: Cannot apply twice to same job
    Given I am logged in as "job_seeker"
    And there is a job posting titled "ICU Nurse"
    And I have already applied to this job
    When I visit the job details page
    Then I should see "You have already applied"
    And I should not see "Apply Now" button

  @job_application @error_handling
  Scenario: Application requires cover letter
    Given I am logged in as "job_seeker"
    And there is a job posting titled "ICU Nurse"
    When I visit the job details page
    And I click "Apply Now"
    And I click "Submit Application" without filling cover letter
    Then I should see "can't be blank"
    And the application should not be created