/**
 * Step to GitHub Issue Mapping
 * Maps step IDs to their corresponding GitHub issue numbers
 * This provides a fallback when dynamic search doesn't find issues
 */

window.stepIssueMapping = {
    // Healthcare Organisation Steps (S1-S8)
    'S1': { issueNumber: 371, title: 'Receive Bemeda sales call' },
    'S2': { issueNumber: 377, title: 'Listen to platform overview' },
    'S3': { issueNumber: null, title: 'Discuss staffing needs' },
    'S4': { issueNumber: null, title: 'Define job requirements' },
    'S5': { issueNumber: null, title: 'Publish job posting' },
    'S6': { issueNumber: null, title: 'Review matched candidates' },
    'S7': { issueNumber: null, title: 'Conduct interviews' },
    'S8': { issueNumber: 376, title: 'Make hiring decision' },
    
    // JobSeeker Steps (S9-S14)
    'S9': { issueNumber: 378, title: 'Create professional profile' },
    'S10': { issueNumber: null, title: 'Receive job notification' },
    'S11': { issueNumber: null, title: 'Review job details' },
    'S12': { issueNumber: null, title: 'Submit application' },
    'S13': { issueNumber: null, title: 'Participate in interview' },
    'S14': { issueNumber: null, title: 'Accept offer & onboard' },
    
    // Sales Team Steps (S15-S19)
    'S15': { issueNumber: null, title: 'Identify target healthcare organisations' },
    'S16': { issueNumber: null, title: 'Make initial contact' },
    'S17': { issueNumber: null, title: 'Present platform benefits' },
    'S18': { issueNumber: null, title: 'Facilitate onboarding' },
    'S19': { issueNumber: null, title: 'Monitor placement & metrics' }
};

// Helper function to get issue info for a step
window.getStepIssueInfo = function(stepId) {
    return stepIssueMapping[stepId.toUpperCase()] || null;
};