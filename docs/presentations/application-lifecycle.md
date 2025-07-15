# Application Lifecycle

## Current State Machine

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Submitted : Submit Application
    Submitted --> UnderReview : Employer Reviews
    UnderReview --> InterviewScheduled : Schedule Interview
    UnderReview --> Rejected : Reject Application
    InterviewScheduled --> OfferExtended : Successful Interview
    InterviewScheduled --> Rejected : Unsuccessful Interview
    OfferExtended --> Accepted : Candidate Accepts
    OfferExtended --> Rejected : Candidate Rejects
    Accepted --> Contracted : Contract Signed
    Contracted --> [*]
    
    classDef implemented fill:#4F46E5,stroke:#333,stroke-width:2px,color:#fff
    class Draft,Submitted,UnderReview,InterviewScheduled,OfferExtended,Accepted,Contracted,Rejected implemented
```

---

## Swiss Enhancement Requirements

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Submitted : Submit Application
    Submitted --> UnderReview : Employer Reviews
    UnderReview --> WorkPermitCheck : Check Permits
    WorkPermitCheck --> InterviewScheduled : Valid Permits
    WorkPermitCheck --> PermitRequired : Need Work Permit
    PermitRequired --> InterviewScheduled : Permit Obtained
    InterviewScheduled --> OfferExtended : Successful Interview
    OfferExtended --> Accepted : Candidate Accepts
    Accepted --> BackgroundCheck : Verify References
    BackgroundCheck --> Contracted : All Clear
    Contracted --> OnPayroll : Add to Payroll
    OnPayroll --> Active : Start Work
    Active --> [*]
    
    classDef implemented fill:#4F46E5,stroke:#333,stroke-width:2px,color:#fff
    classDef critical fill:#EF4444,stroke:#333,stroke-width:2px,color:#fff
    classDef enhancement fill:#F97316,stroke:#333,stroke-width:2px,color:#fff
    
    class Draft,Submitted,UnderReview,InterviewScheduled,OfferExtended,Accepted,Contracted implemented
    class WorkPermitCheck,PermitRequired,OnPayroll critical
    class BackgroundCheck,Active enhancement
```

---

## Implementation Details

### Current Implementation (FSMX)
- **State Machine**: Using FSMX library for state transitions
- **Persistence**: States stored in `job_application_state_transitions` table
- **Events**: Triggered by user actions and system events
- **Validation**: Business rules enforced at transition level

### Required Enhancements
- **Work Permit Integration**: API integration with Swiss authorities
- **Background Checks**: Automated reference verification
- **Payroll Integration**: Connection to Swiss payroll systems
- **Compliance Tracking**: SUVA, AHV, accident insurance