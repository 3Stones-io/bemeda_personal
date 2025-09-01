Feature: T_S001 Cold Call Technical Setup
  In order to support business scenario B_S001
  As the Platform Infrastructure
  We need all technical components working together seamlessly

  Background:
    Given the following technical actors are operational:
      | Actor ID  | Actor Name        | Version | Status  | Endpoint                    |
      | T_F001    | Auth System       | 2.0     | Online  | http://localhost:4000/api/auth |
      | T_F002    | Database          | 1.5     | Online  | postgresql://localhost:5432    |
      | T_F003    | API Router        | 1.0     | Online  | http://localhost:4000/api      |
      | T_F007    | Email Service     | 2.1     | Online  | http://localhost:4000/api/emails |
      | T_F009    | Chat System       | 1.2     | Online  | ws://localhost:4000/socket     |
      | T_F010    | Search Engine     | 1.3     | Online  | http://localhost:4000/api/search |
    And all actors can communicate with each other
    And the system health check returns "OK"

  @technical @t_s001 @crm_integration @parallel_b_s001_us001
  Scenario: T_S001_US001 CRM Logging During Cold Call
    Given the CRM System is integrated and operational
      And the Auth System can authenticate sales team members
      And the Database has the following tables ready:
        | Table Name          | Required Fields                    |
        | organisations       | id, name, status, contact_info     |
        | interactions        | id, type, outcome, timestamp       |
        | sales_activities    | id, sales_rep, prospect, details   |
    When the Auth System receives a login request from Sales Team member
      And the credentials are validated against the Database
      And the Sales Team member calls a Healthcare Organisation
      And the call interaction data is submitted to the API
      And the interaction includes:
        | Field           | Value                              |
        | prospect_id     | healthcare_org_123                 |
        | interaction_type| "cold_call"                        |
        | sales_rep_id    | sales_rep_456                      |
        | outcome         | "interested"                       |
        | duration        | "15 minutes"                       |
        | next_action     | "schedule_follow_up"               |
        | notes           | "Showed interest in ICU nurses"    |
    Then the API Router should validate the interaction data
      And the Database should store the interaction record
      And the interaction should be retrievable by prospect_id
      And the CRM dashboard should show the new interaction
      And the Email Service should send follow-up reminders
      And the parallel business scenario B_S001_US001 should be notified of success

  @technical @t_s001 @dashboard_updates @real_time
  Scenario: T_S001_US002 Sales Dashboard Real-time Updates
    Given the Sales Dashboard is connected via WebSocket
      And the Chat System is handling real-time communications
      And sales team members are authenticated and online
    When a new interaction is logged in the CRM
      And the interaction affects dashboard metrics
      And the update includes:
        | Metric Type     | Update                             |
        | daily_calls     | increment by 1                     |
        | prospect_status | update to "contacted"              |
        | pipeline_value  | add estimated value                |
        | next_actions    | add follow-up task                 |
    Then the Chat System should broadcast the update
      And all connected dashboard instances should receive the update
      And the dashboard should refresh automatically
      And the sales manager should see updated KPIs
      And team members should see their updated activity feeds
      And no manual refresh should be required

  @technical @t_s001 @data_validation @api_contracts
  Scenario: T_S001_US003 API Data Validation and Contracts
    Given the API Router has validation rules for interaction data
      And the Database schema enforces data integrity
      And error handling is configured for invalid requests
    When invalid interaction data is submitted to the API
      And the data is missing required fields:
        | Missing Field   | Expected Type | Validation Rule        |
        | prospect_id     | UUID          | must exist in orgs table |
        | sales_rep_id    | UUID          | must be authenticated user |
        | interaction_type| String        | must be valid enum value  |
        | timestamp       | DateTime      | must be recent (< 1 hour) |
    Then the API Router should reject the invalid request
      And return appropriate HTTP status codes:
        | Error Type          | HTTP Status | Error Message              |
        | missing_prospect_id | 400         | "prospect_id is required"  |
        | invalid_sales_rep   | 401         | "invalid sales rep credentials" |
        | invalid_type        | 422         | "interaction_type must be valid" |
        | stale_timestamp     | 400         | "timestamp too old"        |
      And the Database should not be modified
      And error metrics should be recorded
      And the client should receive clear error messages

  @technical @t_s001 @email_automation @notification_flow
  Scenario: T_S001_US004 Automated Email Notifications
    Given the Email Service is integrated with the CRM system
      And email templates are configured for different scenarios
      And the organisation contact information is available
    When a successful cold call interaction is logged
      And the outcome indicates "interested" or "follow_up_scheduled"
      And the interaction includes organisation contact email
    Then the Email Service should queue appropriate follow-up emails
      And the following emails should be prepared:
        | Email Type        | Recipient         | Template              | Delay   |
        | thank_you         | organisation      | cold_call_thanks      | immediate |
        | information_packet| organisation      | company_info          | 1 hour  |
        | internal_alert    | sales_manager     | prospect_interested   | immediate |
        | follow_up_reminder| sales_rep         | schedule_follow_up    | 24 hours |
      And all emails should be processed through the queue
      And delivery status should be tracked
      And failed deliveries should be retried with backoff
      And email engagement should be tracked

  @technical @t_s001 @search_integration @prospect_matching
  Scenario: T_S001_US005 Prospect Search and Matching
    Given the Search Engine has indexed all healthcare organisations
      And the search criteria include organization size, location, and needs
      And the matching algorithm considers multiple factors
    When a sales rep searches for prospects matching specific criteria
      And the search parameters include:
        | Search Parameter  | Value                              |
        | location_radius   | 50km from Berlin                   |
        | organization_type | "General Hospital"                 |
        | min_bed_count     | 100                                |
        | staffing_needs    | contains "nurses"                  |
        | contact_status    | not "do_not_contact"               |
        | last_contact      | more than 90 days ago              |
    Then the Search Engine should return ranked results
      And results should be ordered by match score
      And each result should include:
        | Result Field      | Information                        |
        | organization_name | official name                      |
        | match_score       | percentage 0-100                   |
        | contact_info      | verified contact details           |
        | last_interaction  | date and outcome                   |
        | estimated_value   | potential business value           |
        | priority_score    | urgency and likelihood             |
      And results should be paginated for performance
      And search analytics should be recorded

  @technical @t_s001 @performance @scalability
  Scenario: T_S001_US006 System Performance Under Load
    Given the system is configured for production load
      And performance monitoring is active
      And load testing tools are available
    When multiple sales team members are active simultaneously
      And the system handles:
        | Load Parameter    | Volume                             |
        | concurrent_users  | 50 sales reps                      |
        | api_requests_sec  | 100 requests per second            |
        | database_queries  | 500 queries per second             |
        | websocket_connections | 50 active connections           |
        | email_queue       | 1000 emails per hour               |
    Then all system components should maintain performance
      And response times should meet SLA requirements:
        | Operation Type    | Max Response Time                  |
        | api_calls         | < 200ms for 95th percentile        |
        | database_queries  | < 50ms for 95th percentile         |
        | websocket_updates | < 100ms delivery time              |
        | search_queries    | < 500ms for complex searches       |
      And system resources should remain within limits
      And no data should be lost or corrupted
      And error rates should stay below 1%

  @technical @t_s001 @security @data_protection
  Scenario: T_S001_US007 Security and Data Protection
    Given security policies are enforced across all components
      And GDPR compliance measures are in place
      And audit logging is enabled for all data access
    When sensitive prospect data is accessed or modified
      And the operations include:
        | Operation         | Data Type                          |
        | view_prospect     | organization contact information   |
        | log_interaction   | call notes and outcomes            |
        | search_prospects  | filtered organization data         |
        | export_reports    | aggregated interaction data        |
    Then all operations should be properly authenticated
      And authorization should be checked for each data access
      And the following security measures should be enforced:
        | Security Measure  | Implementation                     |
        | data_encryption   | AES-256 at rest, TLS 1.3 in transit |
        | access_logging    | all data access logged with user ID |
        | data_anonymization| PII masked in non-prod environments |
        | session_management| secure sessions with timeout        |
        | audit_trail       | immutable log of all changes       |
      And security violations should trigger alerts
      And compliance reports should be automatically generated

  @technical @t_s001 @error_handling @resilience
  Scenario: T_S001_US008 Error Handling and System Resilience  
    Given error handling is implemented across all components
      And system monitoring alerts are configured
      And backup systems are available for critical components
    When system errors occur during cold call logging
      And the errors include:
        | Error Type        | Scenario                           |
        | database_timeout  | DB unavailable for 30 seconds      |
        | email_service_down| email service returns 503 errors   |
        | network_partition | temporary network connectivity loss |
        | high_cpu_load     | system CPU usage above 90%         |
        | memory_exhaustion | available memory below 10%          |
    Then the system should handle errors gracefully
      And the following recovery actions should occur:
        | Error Type        | Recovery Action                    |
        | database_timeout  | retry with exponential backoff     |
        | email_service_down| queue emails for later delivery     |
        | network_partition | cache data locally until reconnect |
        | high_cpu_load     | throttle non-critical operations   |
        | memory_exhaustion | trigger garbage collection          |
      And users should receive appropriate error messages
      And system administrators should be alerted
      And the system should recover automatically when possible
      And no data should be lost during error conditions