@bdd
Feature: Interview Scheduling
  As an employer
  I want to schedule interviews with candidates
  So that I can evaluate them for positions

  Background:
    Given I am logged in as "employer"
    And I have a company profile
    And my company has a job with 1 applications

  @scheduling
  Scenario: Schedule an interview
    Given I am viewing the application
    When I click "Schedule a meeting"
    And I fill in interview date with "2024-02-15"
    And I fill in interview time with "14:00"
    And I fill in interview duration with "60"
    And I fill in interview location with "https://meet.example.com/room"
    And I click "Done"
    Then I should see "Interview scheduled"
    And the interview should be in the database

  @scheduling @job_seeker
  Scenario: Candidate views interview invitation
    Given I am logged in as "job_seeker"
    And an employer has scheduled an interview with me
    When I visit my interviews page
    Then I should see the interview invitation
    And I should see interview date and time
