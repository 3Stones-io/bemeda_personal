Feature: B_S001 Cold Call to Candidate Placement
  In order to connect qualified healthcare professionals with healthcare organizations
  As a Healthcare Recruitment Platform
  We need to facilitate complete placement workflows from initial contact to successful hiring

  Background:
    Given the platform is operational
    And the following actors are available:
      | Actor Type      | Actor Name         | Status      | Capabilities                    |
      | Human           | Sales Team         | Active      | call, present, negotiate        |
      | Human           | Healthcare Org     | Prospect    | evaluate, decide, hire          |
      | Human           | Job Seeker         | Registered  | apply, interview, accept        |
      | System          | CRM System         | Online      | log, track, notify              |
      | System          | Email Service      | Online      | send, deliver, track            |
      | System          | Matching Engine    | Online      | match, rank, recommend          |
      | System          | Auth System        | Online      | authenticate, authorize         |
      | System          | Database           | Online      | store, retrieve, update         |

  @business @b_s001 @cold_call @healthcare_org @sales_team
  Scenario: B_S001_US001 Organisation Receives Cold Call
    Given a Healthcare Organisation exists as a qualified prospect
      And the organisation has the following profile:
        | Field             | Value                    |
        | name              | "Test Hospital"          |
        | type              | "General Hospital"       |
        | size              | "200+ beds"              |
        | location          | "Berlin, Germany"        |
        | staffing_needs    | "nurses,doctors"         |
        | status            | "prospect"               |
    And the Sales Team has researched their staffing needs
      And the research includes:
        | Research Area     | Finding                  |
        | current_staff     | "50 nurses, 20 doctors" |
        | turnover_rate     | "15% annually"           |
        | urgent_needs      | "ICU nurses"             |
        | budget_range      | "€50k-80k per placement"|
    When the Sales Team calls the Healthcare Organisation
      And presents our value proposition
      And explains our placement success rate of "92%"
      And offers a "no placement, no fee" guarantee
    Then the Healthcare Organisation should understand our value proposition
      And their understanding level should be at least 8 out of 10
      And they should express interest in our services
      And they should agree to schedule a detailed discussion
      And the interaction should be logged in the CRM System
      
    # Parallel scenario execution
    And the following parallel scenarios should execute successfully:
      | Scenario    | Type      | Expected Result           |
      | T_S001_US001| Technical | CRM logging successful    |
      | U_S001_US001| UX        | Sales dashboard updated   |

  @business @b_s001 @discussion @needs_analysis
  Scenario: B_S001_US002 Discuss Staffing Needs
    Given the Healthcare Organisation has agreed to a detailed discussion
      And a follow-up meeting is scheduled within 48 hours
      And the Sales Team has prepared relevant case studies
    When the Sales Team presents our staffing solutions
      And shows case studies from similar healthcare organizations
      And demonstrates our candidate vetting process
      And explains our 90-day replacement guarantee
    Then the Healthcare Organisation should understand our process
      And they should share their specific staffing challenges
      And they should provide details about:
        | Detail Type       | Required Information     |
        | positions_needed  | specific roles and count |
        | timeline          | when positions needed    |
        | requirements      | skills and certifications|
        | budget_approval   | decision maker and budget|
      And they should show willingness to proceed with job posting
      And a job posting timeline should be established

  @business @b_s001 @job_posting @agreement
  Scenario: B_S001_US003 Agree to Job Posting
    Given the Healthcare Organisation understands our process
      And they have shared their staffing requirements
      And budget approval has been confirmed
    When the Sales Team proposes a specific job posting plan
      And presents our fee structure
      And explains the candidate sourcing strategy
      And sets realistic timeline expectations
    Then the Healthcare Organisation should agree to proceed
      And they should sign our service agreement
      And they should approve the job posting content
      And they should provide necessary hiring authorization
      And the job posting should be scheduled for publication

  @business @b_s001 @candidate_review @matching
  Scenario: B_S001_US004 Review Matched Candidates
    Given a job posting has been published for at least 7 days
      And the Matching Engine has identified potential candidates
      And candidates have been pre-screened by our team
    When matched candidates are presented to the Healthcare Organisation
      And candidate profiles include:
        | Profile Section   | Information Included     |
        | qualifications    | certifications, degrees  |
        | experience        | years, previous roles    |
        | availability      | start date, schedule     |
        | references        | contact information      |
        | background_check  | clearance status         |
    Then the Healthcare Organisation should review all candidates
      And they should select candidates for interviews
      And they should provide feedback on rejected candidates
      And interview schedules should be coordinated
      And our team should facilitate the interview process

  @business @b_s001 @interviews @selection
  Scenario: B_S001_US005 Conduct Interviews
    Given candidates have been selected for interviews
      And interview schedules have been confirmed
      And both parties have been prepared for the process
    When interviews are conducted
      And our team provides interview support as needed
      And candidate feedback is collected
      And organisation feedback is gathered
    Then the Healthcare Organisation should evaluate all candidates
      And they should select their preferred candidate(s)
      And they should provide clear reasoning for their choice
      And our team should communicate decisions to all candidates
      And successful candidates should receive preliminary offers

  @business @b_s001 @hiring @completion
  Scenario: B_S001_US006 Complete Hiring Process
    Given a candidate has been selected by the Healthcare Organisation
      And preliminary offers have been extended
      And candidate has expressed acceptance
    When final negotiations are completed
      And employment contracts are finalized
      And background checks are completed
      And start dates are confirmed
    Then the candidate should be successfully placed
      And all paperwork should be completed
      And our placement fee should be processed
      And a 90-day follow-up schedule should be established
      And the placement should be marked as successful in our system

  # Job Seeker Journey Scenarios
  
  @business @b_s001 @job_seeker @profile_creation
  Scenario: B_S001_US007 JobSeeker Creates Profile
    Given a healthcare professional is looking for new opportunities
      And they have heard about our platform
      And they meet basic qualification requirements
    When they visit our platform registration page
      And complete their professional profile including:
        | Profile Section   | Required Information     |
        | personal_info     | name, contact details    |
        | qualifications    | licenses, certifications |
        | experience        | work history, specialties|
        | preferences       | location, salary, schedule|
        | availability      | start date preferences   |
    Then their profile should be created successfully
      And they should receive a welcome email
      And their profile should be verified by our team
      And they should be added to our candidate database
      And they should be eligible for job matching

  @business @b_s001 @job_seeker @notifications
  Scenario: B_S001_US008 Receive Job Notification
    Given a Job Seeker has a complete and verified profile
      And new job opportunities matching their criteria are available
      And the Matching Engine has identified them as a good fit
    When our system identifies matching opportunities
      And the match score is above 75%
      And the job requirements align with their qualifications
    Then they should receive a job notification
      And the notification should include:
        | Notification Content | Details                |
        | job_summary         | role, location, type   |
        | match_percentage    | compatibility score    |
        | organisation_info   | hospital name, size    |
        | next_steps          | how to apply           |
        | timeline            | application deadline   |
      And they should be able to apply directly from the notification
      And their application status should be tracked

  @business @b_s001 @job_seeker @application
  Scenario: B_S001_US009 Review and Apply
    Given a Job Seeker has received a job notification
      And they are interested in the opportunity
      And they have reviewed the job requirements
    When they decide to apply for the position
      And they submit their application through our platform
      And provide any additional required information
    Then their application should be submitted successfully
      And the Healthcare Organisation should be notified
      And the application should appear in the organisation's review queue
      And the Job Seeker should receive confirmation of their application
      And they should be able to track their application status

  @business @b_s001 @job_seeker @interview_participation
  Scenario: B_S001_US010 Participate in Interview
    Given a Job Seeker's application has been reviewed positively
      And they have been selected for an interview
      And the interview has been scheduled
    When they participate in the interview process
      And answer questions about their qualifications and experience
      And ask relevant questions about the role and organization
    Then they should complete the interview successfully
      And provide post-interview feedback to our team
      And wait for the organisation's decision
      And maintain communication with our placement team

  @business @b_s001 @job_seeker @offer_acceptance
  Scenario: B_S001_US011 Receive Job Offer
    Given a Job Seeker has completed the interview process
      And the Healthcare Organisation has selected them
      And offer terms have been negotiated
    When they receive a formal job offer
      And the offer meets their stated preferences
      And our team has reviewed the offer terms
    Then they should evaluate the offer carefully
      And make a decision within the agreed timeframe
      And communicate their decision to our team
      And if accepted, proceed with onboarding preparations

  @business @b_s001 @job_seeker @onboarding
  Scenario: B_S001_US012 Complete Onboarding
    Given a Job Seeker has accepted a job offer
      And all pre-employment requirements are complete
      And their start date has been confirmed
    When they begin their new position
      And complete organizational onboarding
      And our team provides support during transition
    Then they should be successfully integrated into their new role
      And their placement should be confirmed as successful
      And they should provide feedback on our placement process
      And they should remain in our network for future opportunities

  # Sales Team Scenarios

  @business @b_s001 @sales_team @prospecting
  Scenario: B_S001_US013 Identify Healthcare Org (Sales Team)
    Given the Sales Team is actively prospecting for new clients
      And they have access to healthcare industry databases
      And they understand our ideal client profile
    When they research potential healthcare organizations
      And identify organizations with staffing challenges
      And qualify prospects based on:
        | Qualification Criteria | Requirements           |
        | organization_size      | 50+ beds or staff      |
        | staffing_budget       | €100k+ annual budget  |
        | decision_authority    | access to hiring managers |
        | geographical_fit      | within service area    |
        | current_pain_points   | active staffing issues |
    Then qualified prospects should be identified
      And prospect information should be entered into CRM
      And initial contact strategy should be planned
      And contact attempts should be scheduled

  @business @b_s001 @sales_team @initial_contact
  Scenario: B_S001_US014 Make Initial Contact (Sales Team)
    Given qualified prospects have been identified
      And contact information has been verified
      And approach strategy has been planned
    When the Sales Team makes initial contact
      And introduces our platform and services
      And identifies the right decision maker
      And establishes rapport and credibility
    Then initial contact should be successful
      And prospect interest should be assessed
      And follow-up meetings should be scheduled if appropriate
      And contact results should be logged in CRM
      And next steps should be clearly defined

  @business @b_s001 @sales_team @presentation
  Scenario: B_S001_US015 Present Platform Benefits (Sales Team)
    Given initial contact has been successful
      And a presentation meeting has been scheduled
      And the Sales Team has prepared relevant materials
    When presenting our platform benefits
      And demonstrating our candidate quality
      And explaining our success rates and guarantees
      And addressing specific organization needs
    Then the Healthcare Organisation should understand our value
      And they should see clear benefits for their situation
      And objections should be addressed satisfactorily
      And next steps should be agreed upon
      And decision timeline should be established

  @business @b_s001 @sales_team @onboarding_facilitation
  Scenario: B_S001_US016 Facilitate Onboarding (Sales Team)
    Given a Healthcare Organisation has agreed to use our services
      And contracts have been signed
      And initial job postings are ready
    When facilitating client onboarding
      And introducing them to our account management team
      And setting up their organization profile
      And establishing communication preferences
    Then the client should be fully onboarded
      And they should understand how to use our platform
      And job posting processes should be established
      And ongoing support channels should be clear

  @business @b_s001 @sales_team @success_monitoring
  Scenario: B_S001_US017 Monitor Placement Success (Sales Team)
    Given placements have been made for the client
      And the 90-day evaluation period is underway
      And regular check-ins have been scheduled
    When monitoring placement success
      And gathering feedback from both parties
      And addressing any issues that arise
      And tracking placement retention rates
    Then placement success should be confirmed
      And any problems should be resolved quickly
      And client satisfaction should be maintained
      And opportunities for additional placements should be identified

  @business @b_s001 @sales_team @follow_up_opportunities
  Scenario: B_S001_US018 Follow-up Opportunities (Sales Team)
    Given successful placements have been completed
      And the client relationship is established
      And additional staffing needs may exist
    When following up on additional opportunities
      And maintaining regular client communication
      And identifying new staffing challenges
      And proposing solutions for ongoing needs
    Then additional business opportunities should be identified
      And client relationship should be strengthened
      And repeat business should be generated
      And referral opportunities should be explored