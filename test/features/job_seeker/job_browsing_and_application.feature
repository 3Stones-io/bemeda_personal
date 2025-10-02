@bdd
Feature: Job Browsing and Application
  As a job seeker
  I want to browse available jobs and apply to positions
  So that I can find employment in the healthcare sector

  @smoke @job_seeker
  Scenario: Browse jobs without authentication
    Given there are 10 active job postings
    When I visit the jobs page
    Then I should see a list of job postings
    And each job should show title, company, and location
    And I should see "Sign in to apply" message

  @smoke @job_seeker
  Scenario: Filter jobs by location
    Given there are jobs in "Zürich", "Bern", and "Geneva"
    When I visit the jobs page
    And I select "Zürich" from location filter
    Then I should only see jobs in "Zürich"
    And I should not see jobs from other locations

  @smoke @job_seeker
  Scenario: Apply for job with complete profile
    Given I am logged in as "job_seeker"
    And there is a job posting titled "ICU Nurse"
    When I visit the job details page
    And I click "Apply Now"
    And I fill in "Cover Letter" with "I am interested in this position"
    And I click "Submit Application"
    Then I should see "Application submitted successfully"
    And the application should be in the database

  @job_seeker
  Scenario: View application status
    Given I am logged in as "job_seeker"
    And I have applied to 3 jobs
    When I visit "My Applications"
    Then I should see all 3 applications
    And each application should show status and date