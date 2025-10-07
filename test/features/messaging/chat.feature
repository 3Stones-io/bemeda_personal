@bdd
Feature: Messaging and Chat
  As an employer or job seeker
  I want to communicate about job applications
  So that I can discuss opportunities and clarify details

  Background:
    Given there is a job application for discussion

  @messaging @chat
  Scenario: Employer sends message to job seeker
    Given I authenticate as the employer
    When I visit the job application chat page
    And I send a message "We would like to schedule an interview"
    Then I should see "We would like to schedule an interview"
    And the message should be stored in the conversation

  @messaging @chat
  Scenario: Job seeker receives and replies to message
    Given I authenticate as the job seeker
    And the employer has sent me a message
    When I visit the job application chat page
    Then I should see the employer message
    When I reply with "I am available next week"
    Then I should see "I am available next week"
    And the employer should receive my reply

  @messaging @chat
  Scenario: View message history
    Given I authenticate as the employer
    And there is an existing conversation with the job seeker
    When I visit the job application chat page
    Then I should see all messages in chronological order
    And each message should show the sender name
