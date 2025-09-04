/**
 * GitHub Fallback Data
 * Contains pre-fetched issue data for when API calls fail due to CORS or rate limits
 */

window.githubFallbackData = {
    'S1': {
        issue: {
            number: 371,
            title: "S1: Receive Bemeda sales call",
            state: "open",
            html_url: "https://github.com/3Stones-io/bemeda_personal/issues/371",
            created_at: "2025-09-01T18:54:43Z",
            updated_at: "2025-09-01T19:22:41Z",
            body: `## Step Description
Healthcare organisation receives initial sales call from Bemeda team introducing the talent platform and its benefits for healthcare staffing needs.

## Actor
A1: Healthcare Organisation

## Key Activities
- Bemeda sales representative introduces the platform
- Healthcare organisation shares current staffing challenges  
- Initial qualification and needs assessment
- Agreement to proceed with platform demonstration

## Related Components
**UX Components:**
- Uses UX: #372 (U1: Call Reception Dashboard)
- Uses UX: #374 (U25: Form Fields Component - Shared with S5, S9)

**Technical Components:**
- Uses Tech: #373 (T1: Contact Capture API)
- Uses Tech: #TBD (T2: Call Logging Service)
- Uses Tech: #TBD (T3: Company Schema)

## Acceptance Criteria
- [ ] Sales call successfully initiated and completed
- [ ] Healthcare organisation contact information captured
- [ ] Initial needs assessment documented
- [ ] Next steps (platform demo) scheduled
- [ ] Call details logged in CRM system
- [ ] Follow-up actions assigned

## Implementation Notes
This is the entry point for the entire healthcare recruitment workflow. Success here determines the quality of the entire customer relationship.`,
            labels: [
                { name: "priority:high", color: "d73a49" },
                { name: "scenario:s001", color: "8e24aa" },
                { name: "status:todo", color: "ffffff" },
                { name: "step:S1", color: "1976d2" },
                { name: "actor:A1", color: "e65100" }
            ],
            user: {
                login: "DenisMGojak",
                avatar_url: "https://avatars.githubusercontent.com/u/189635068?v=4"
            }
        },
        comments: [],
        crossReferences: []
    },
    
    'S2': {
        issue: {
            number: 377,
            title: "S2: Listen to platform overview",
            state: "open", 
            html_url: "https://github.com/3Stones-io/bemeda_personal/issues/377",
            created_at: "2025-09-02T12:00:00Z",
            updated_at: "2025-09-02T12:00:00Z",
            body: `## Step Description
Healthcare organisation receives comprehensive platform demonstration from Bemeda sales team.

### Acceptance Criteria
- [ ] Platform features demonstrated
- [ ] Questions and concerns addressed
- [ ] ROI and cost structure explained
- [ ] Timeline for implementation discussed
- [ ] Next steps agreed upon

### Related Components
- **UX**: Demo presentation interface, interactive walkthrough
- **Technical**: Demo environment, presentation API

### Actor
A1 - Healthcare Organisation

### Step Type
Information Gathering`,
            labels: [
                { name: "priority:high", color: "d73a49" },
                { name: "status:todo", color: "ffffff" }
            ],
            user: {
                login: "DenisMGojak",
                avatar_url: "https://avatars.githubusercontent.com/u/189635068?v=4"
            }
        },
        comments: [],
        crossReferences: []
    },
    
    'S8': {
        issue: {
            number: 376,
            title: "S8: Make hiring decision",
            state: "open",
            html_url: "https://github.com/3Stones-io/bemeda_personal/issues/376", 
            created_at: "2025-09-02T11:30:00Z",
            updated_at: "2025-09-02T11:30:00Z",
            body: `## Step Description
Healthcare organisation makes final hiring decision after completing interview process and reference checks.

### Acceptance Criteria
- [ ] Candidate evaluation complete
- [ ] Reference checks performed
- [ ] Hiring committee decision documented
- [ ] Offer terms prepared
- [ ] Internal approvals obtained

### Related Components
- **UX**: Decision dashboard, offer management UI
- **Technical**: Decision workflow API, approval service

### Actor
A1 - Healthcare Organisation

### Step Type
Process Completion`,
            labels: [
                { name: "priority:high", color: "d73a49" },
                { name: "status:todo", color: "ffffff" }
            ],
            user: {
                login: "DenisMGojak", 
                avatar_url: "https://avatars.githubusercontent.com/u/189635068?v=4"
            }
        },
        comments: [],
        crossReferences: []
    },
    
    'S9': {
        issue: {
            number: 378,
            title: "S9: Create professional profile",
            state: "open",
            html_url: "https://github.com/3Stones-io/bemeda_personal/issues/378",
            created_at: "2025-09-02T11:45:00Z", 
            updated_at: "2025-09-02T11:45:00Z",
            body: `## Step Description
JobSeeker creates comprehensive professional profile including credentials, experience, and preferences.

### Acceptance Criteria
- [ ] Personal information completed
- [ ] Professional credentials uploaded
- [ ] Work history documented
- [ ] Skills and certifications listed
- [ ] Job preferences configured
- [ ] Profile validation passed

### Related Components
- **UX**: Profile creation wizard, document upload interface
- **Technical**: Profile storage API, document validation service

### Actor
A2 - JobSeeker

### Step Type
User Onboarding`,
            labels: [
                { name: "priority:high", color: "d73a49" },
                { name: "status:todo", color: "ffffff" }
            ],
            user: {
                login: "DenisMGojak",
                avatar_url: "https://avatars.githubusercontent.com/u/189635068?v=4"
            }
        },
        comments: [],
        crossReferences: []
    }
};

// Helper function to get fallback data for a step
window.getFallbackStepData = function(stepId) {
    const data = window.githubFallbackData[stepId.toUpperCase()];
    if (data) {
        return {
            stepId: stepId,
            issue: data.issue,
            comments: data.comments,
            crossReferences: data.crossReferences,
            lastUpdated: new Date().toISOString(),
            dataSource: 'fallback'
        };
    }
    return null;
};