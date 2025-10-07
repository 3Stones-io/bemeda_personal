@bdd @admin_dashboard
Feature: Admin Dashboard
  As an administrator
  I want to view comprehensive system statistics
  So that I can monitor platform activity and user engagement

  Background:
    Given I am authenticated as admin

  @admin_dashboard
  Scenario: View dashboard statistics overview
    When I visit the admin dashboard
    Then I should see total user statistics
    And I should see total company statistics
    And I should see total job posting statistics
    And I should see total application statistics

  @admin_dashboard
  Scenario: View application status breakdown
    Given there are applications with different statuses
    When I visit the admin dashboard
    Then I should see the application status breakdown
    And I should see "applied" status count
    And I should see "offer_extended" status count

  @admin_dashboard
  Scenario: View recent activity sections
    Given there are recent users, job postings, and applications
    When I visit the admin dashboard
    Then I should see recent users section
    And I should see recent job postings section
    And I should see recent applications section

  @admin_dashboard
  Scenario: View time-series charts
    When I visit the admin dashboard
    Then I should see the registrations chart placeholder
    And I should see the applications chart placeholder
