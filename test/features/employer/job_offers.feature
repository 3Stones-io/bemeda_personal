@bdd @job_offers
Feature: Job Offers
  As an employer
  I want to create and manage job offers
  So that I can formally extend job offers to candidates

  Background:
    Given I am logged in as "employer"
    And I have a company profile
    And my company has a job with 1 applications

  @job_offers
  Scenario: Employer creates and sends job offer
    Given I am viewing the application
    When I click "Extend Offer"
    And I fill in job offer variables
    And I click "Send Offer"
    Then I should see "Job offer created successfully"
    And the job offer should be in the database

  @job_offers @job_seeker
  Scenario: Job seeker views received job offer
    Given I am logged in as "job_seeker"
    And an employer has sent me a job offer
    When I visit my job applications page
    Then I should see the job offer details
    And I should see job offer status

  @job_offers @job_seeker
  Scenario: Job seeker accepts job offer
    Given I am logged in as "job_seeker"
    And an employer has sent me a job offer
    When I visit the job offer page
    And I click "Accept Offer"
    Then I should see "Job offer accepted"
    And the job offer status should be "extended"

  @job_offers @contract
  Scenario: Job offer contract lifecycle
    Given I am logged in as "employer"
    And I have created a job offer for an application
    When I generate the contract
    Then the job offer should have a generated contract timestamp
    And I should see contract generation confirmation
