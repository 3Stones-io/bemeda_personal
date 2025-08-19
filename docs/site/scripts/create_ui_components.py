#!/usr/bin/env python3
"""
Create UI component documentation files for JOB Scenario 1 elements.
"""

import os
from pathlib import Path

# Component data from JOB Scenario 1 analysis
components = [
    {
        "id": "UI-001",
        "name": "Organisation Dashboard",
        "filename": "UI-001-dashboard-organisation.html",
        "description": "Main organisational dashboard for healthcare facilities to manage job postings, view matched candidates, and track recruitment progress in the Bemeda platform.",
        "category": "Dashboard",
        "status": "Ready",
        "user_type": "Healthcare Organisation",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Job Posting Management", "desc": "Create, edit, and manage active job postings with detailed requirements and preferences."},
            {"title": "Candidate Overview", "desc": "View matched candidates, their profiles, and application status in real-time."},
            {"title": "Analytics & Insights", "desc": "Track posting performance, application rates, and recruitment metrics."},
            {"title": "Communication Hub", "desc": "Manage all candidate communications and interview scheduling from one place."},
            {"title": "Compliance Tracking", "desc": "Monitor regulatory compliance and certification requirements for healthcare roles."},
            {"title": "Quick Actions", "desc": "Fast access to common tasks like posting new jobs, reviewing applications, and scheduling interviews."}
        ]
    },
    {
        "id": "UI-002",
        "name": "Job Form",
        "filename": "UI-002-job-form.html",
        "description": "Comprehensive form for healthcare organisations to create detailed job postings with specific requirements, qualifications, and preferences.",
        "category": "Form Elements",
        "status": "Ready",
        "user_type": "Healthcare Organisation",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Job Details", "desc": "Title, description, department, and role-specific information."},
            {"title": "Requirements", "desc": "Education, certifications, experience, and skill requirements."},
            {"title": "Location & Schedule", "desc": "Work location, schedule type, shift patterns, and remote options."},
            {"title": "Compensation", "desc": "Salary ranges, benefits, and additional compensation details."},
            {"title": "Application Settings", "desc": "Deadline, application process, and required documents."},
            {"title": "Publishing Options", "desc": "Visibility settings, approval workflow, and posting duration."}
        ]
    },
    {
        "id": "UI-003",
        "name": "Candidate List",
        "filename": "UI-003-candidate-list.html",
        "description": "Interface for healthcare organisations to view, filter, and review matched candidates for their job postings with detailed profiles and matching scores.",
        "category": "Data Display",
        "status": "Progress",
        "user_type": "Healthcare Organisation",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Candidate Profiles", "desc": "Comprehensive view of candidate qualifications, experience, and certifications."},
            {"title": "Matching Score", "desc": "Algorithm-based compatibility rating for each candidate."},
            {"title": "Filtering & Search", "desc": "Advanced filters by skills, location, availability, and experience."},
            {"title": "Application Status", "desc": "Track application progress and candidate responses."},
            {"title": "Quick Actions", "desc": "Shortlist, reject, or invite candidates with one-click actions."},
            {"title": "Bulk Operations", "desc": "Manage multiple candidates simultaneously for efficiency."}
        ]
    },
    {
        "id": "UI-004",
        "name": "Interview Tool",
        "filename": "UI-004-interview-tool.html",
        "description": "Integrated tool for healthcare organisations to schedule, conduct, and manage interviews with candidates, including video conferencing and assessment features.",
        "category": "Interactive Tools",
        "status": "Pending",
        "user_type": "Healthcare Organisation",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Interview Scheduling", "desc": "Calendar integration and automated scheduling with candidates."},
            {"title": "Video Conferencing", "desc": "Built-in video call functionality for remote interviews."},
            {"title": "Interview Templates", "desc": "Standardized question sets for different healthcare roles."},
            {"title": "Assessment Tools", "desc": "Skills evaluation and competency testing during interviews."},
            {"title": "Notes & Scoring", "desc": "Real-time note-taking and candidate scoring system."},
            {"title": "Collaboration", "desc": "Multi-interviewer support and team feedback collection."}
        ]
    },
    {
        "id": "UI-005",
        "name": "Profile Form",
        "filename": "UI-005-profile-form.html",
        "description": "Comprehensive profile creation form for healthcare professionals to showcase their qualifications, experience, and preferences on the Bemeda platform.",
        "category": "Form Elements",
        "status": "Ready",
        "user_type": "JobSeeker (Healthcare Professional)",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Personal Information", "desc": "Basic details, contact information, and professional photo upload."},
            {"title": "Professional Background", "desc": "Work history, positions held, and healthcare experience."},
            {"title": "Qualifications", "desc": "Education, certifications, licenses, and continuing education."},
            {"title": "Skills & Specializations", "desc": "Clinical skills, specialties, and technical competencies."},
            {"title": "Preferences", "desc": "Job preferences, location, salary expectations, and availability."},
            {"title": "Portfolio", "desc": "Document uploads for CV, certificates, and references."}
        ]
    },
    {
        "id": "UI-006",
        "name": "Job Browser",
        "filename": "UI-006-job-browser.html",
        "description": "Search and discovery interface for healthcare professionals to find and explore job opportunities that match their skills and preferences.",
        "category": "Navigation",
        "status": "Ready",
        "user_type": "JobSeeker (Healthcare Professional)",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Advanced Search", "desc": "Filter jobs by specialty, location, salary, and requirements."},
            {"title": "Job Recommendations", "desc": "Personalized job suggestions based on profile and preferences."},
            {"title": "Job Details", "desc": "Comprehensive job descriptions with requirements and benefits."},
            {"title": "Save & Track", "desc": "Save interesting positions and track application status."},
            {"title": "Quick Apply", "desc": "One-click application process for suitable positions."},
            {"title": "Match Score", "desc": "Compatibility rating showing how well the job fits the candidate."}
        ]
    },
    {
        "id": "UI-007",
        "name": "Application Interface",
        "filename": "UI-007-application-interface.html",
        "description": "Application submission and tracking interface for healthcare professionals to apply for positions and monitor their application progress.",
        "category": "Form Elements",
        "status": "Progress",
        "user_type": "JobSeeker (Healthcare Professional)",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Application Form", "desc": "Customizable application form with role-specific questions."},
            {"title": "Document Upload", "desc": "Upload CV, cover letter, certificates, and references."},
            {"title": "Application Tracking", "desc": "Real-time status updates and application progress."},
            {"title": "Communication Log", "desc": "History of all interactions with the employer."},
            {"title": "Interview Scheduling", "desc": "Self-service interview scheduling and calendar integration."},
            {"title": "Application Analytics", "desc": "Insights on application performance and feedback."}
        ]
    },
    {
        "id": "UI-008",
        "name": "Messages Interface",
        "filename": "UI-008-messages-interface.html",
        "description": "Messaging system for secure communication between healthcare professionals, organisations, and the sales team throughout the recruitment process.",
        "category": "Communication",
        "status": "Pending",
        "user_type": "All Users (Multi-party)",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Secure Messaging", "desc": "HIPAA-compliant messaging for healthcare recruitment communications."},
            {"title": "Thread Management", "desc": "Organized conversation threads by job application or inquiry."},
            {"title": "File Sharing", "desc": "Secure document sharing and attachment management."},
            {"title": "Notifications", "desc": "Real-time and email notifications for new messages."},
            {"title": "Message History", "desc": "Complete communication history with search functionality."},
            {"title": "Multi-party Chat", "desc": "Group conversations including candidate, employer, and sales team."}
        ]
    },
    {
        "id": "UI-009",
        "name": "CRM Dashboard",
        "filename": "UI-009-crm-dashboard.html",
        "description": "Customer relationship management dashboard for the Bemeda sales team to manage client relationships, track leads, and monitor business performance.",
        "category": "Dashboard",
        "status": "Ready",
        "user_type": "Sales Team",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Client Overview", "desc": "Comprehensive view of all healthcare organisation clients and prospects."},
            {"title": "Lead Management", "desc": "Track and manage potential clients through the sales pipeline."},
            {"title": "Activity Tracking", "desc": "Log and monitor all client interactions and touchpoints."},
            {"title": "Performance Metrics", "desc": "Sales KPIs, conversion rates, and revenue analytics."},
            {"title": "Task Management", "desc": "Follow-up reminders and sales task automation."},
            {"title": "Reporting Tools", "desc": "Generate client reports and business intelligence insights."}
        ]
    },
    {
        "id": "UI-010",
        "name": "Lead Forms",
        "filename": "UI-010-lead-forms.html",
        "description": "Lead capture and management forms for the sales team to collect and qualify potential healthcare organisation clients.",
        "category": "Form Elements",
        "status": "Progress",
        "user_type": "Sales Team",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Lead Capture", "desc": "Forms to collect potential client information and requirements."},
            {"title": "Qualification Questions", "desc": "Standardized questions to assess lead quality and fit."},
            {"title": "Contact Management", "desc": "Store and organize lead contact information and preferences."},
            {"title": "Lead Scoring", "desc": "Automated scoring based on organisation size, needs, and budget."},
            {"title": "Follow-up Automation", "desc": "Automated email sequences and task creation."},
            {"title": "Integration", "desc": "Seamless integration with CRM dashboard and analytics."}
        ]
    },
    {
        "id": "UI-011",
        "name": "Analytics Dashboard",
        "filename": "UI-011-analytics-dashboard.html",
        "description": "Performance analytics and reporting dashboard for the sales team to track business metrics, client performance, and platform usage.",
        "category": "Data Display",
        "status": "Progress",
        "user_type": "Sales Team",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Sales Metrics", "desc": "Revenue, conversion rates, and sales pipeline analytics."},
            {"title": "Client Analytics", "desc": "Client engagement, job posting activity, and success rates."},
            {"title": "Platform Usage", "desc": "User activity, feature adoption, and system performance."},
            {"title": "Custom Reports", "desc": "Generate tailored reports for different stakeholders."},
            {"title": "Data Visualization", "desc": "Interactive charts, graphs, and performance dashboards."},
            {"title": "Export & Sharing", "desc": "Export data and share reports with team members and clients."}
        ]
    },
    {
        "id": "UI-012",
        "name": "Automation Tools",
        "filename": "UI-012-automation-tools.html",
        "description": "Automated workflow and follow-up management tools for the sales team to streamline client onboarding and relationship management.",
        "category": "Automation",
        "status": "Pending",
        "user_type": "Sales Team",
        "scenario": "JOB S1 - Permanent Placement",
        "features": [
            {"title": "Workflow Builder", "desc": "Create custom automated workflows for client onboarding and follow-up."},
            {"title": "Email Automation", "desc": "Automated email sequences based on client actions and timeline."},
            {"title": "Task Automation", "desc": "Automatically create and assign tasks based on triggers."},
            {"title": "Client Onboarding", "desc": "Streamlined automated onboarding process for new healthcare clients."},
            {"title": "Follow-up Scheduling", "desc": "Intelligent scheduling of follow-up activities and check-ins."},
            {"title": "Integration Hub", "desc": "Connect with external tools and systems for seamless workflow."}
        ]
    }
]

def get_status_class(status):
    """Get CSS class for status badge."""
    status_map = {
        "Ready": "status-ready",
        "Progress": "status-progress", 
        "Pending": "status-pending"
    }
    return status_map.get(status, "status-pending")

def get_status_color(status):
    """Get background color for status."""
    if status == "Ready":
        return "background: #d4edda; color: #155724;"
    elif status == "Progress":
        return "background: #cce5ff; color: #004085;"
    else:  # Pending
        return "background: #fff3cd; color: #856404;"

def create_component_file(component):
    """Create a component documentation file."""
    
    template = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{component['id']} {component['name']} - Bemeda Design System</title>
    <link rel="stylesheet" href="../../assets/global/css/language-switcher.css">
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f5f5f7;
        }}
        
        .container {{
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }}
        
        /* Component Header */
        .component-header {{
            background: white;
            border-radius: 12px;
            padding: 32px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 32px;
        }}
        
        .component-id {{
            display: inline-block;
            background: #0066cc;
            color: white;
            padding: 6px 16px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 1.1rem;
            margin-bottom: 16px;
        }}
        
        .component-title {{
            font-size: 2.5rem;
            font-weight: 600;
            color: #1a1a1a;
            margin-bottom: 16px;
        }}
        
        .component-description {{
            font-size: 1.2rem;
            color: #666;
            max-width: 800px;
        }}
        
        /* Component Info Grid */
        .info-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-top: 24px;
            padding-top: 24px;
            border-top: 1px solid #e0e0e0;
        }}
        
        .info-item {{
            display: flex;
            flex-direction: column;
            gap: 4px;
        }}
        
        .info-label {{
            font-size: 0.9rem;
            color: #666;
            font-weight: 500;
        }}
        
        .info-value {{
            font-size: 1rem;
            color: #1a1a1a;
        }}
        
        /* Status Badge */
        .status-badge {{
            {get_status_color(component['status'])}
            padding: 4px 12px;
            border-radius: 4px;
            font-weight: 500;
            display: inline-block;
        }}
        
        /* Back Link */
        .back-link {{
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: #0066cc;
            text-decoration: none;
            margin-bottom: 20px;
            font-weight: 500;
        }}
        
        .back-link:hover {{
            text-decoration: underline;
        }}
        
        /* Design Section */
        .design-section {{
            background: white;
            border-radius: 12px;
            padding: 32px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 32px;
        }}
        
        .section-header {{
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 24px;
            padding-bottom: 16px;
            border-bottom: 2px solid #f0f0f0;
        }}
        
        .section-icon {{
            font-size: 1.5rem;
        }}
        
        .section-title {{
            font-size: 1.5rem;
            font-weight: 600;
            color: #1a1a1a;
        }}
        
        .design-preview {{
            background: #f8f9fa;
            border-radius: 8px;
            padding: 24px;
            margin-bottom: 24px;
            min-height: 300px;
            display: flex;
            align-items: center;
            justify-content: center;
            border: 2px dashed #e0e0e0;
        }}
        
        .design-placeholder {{
            text-align: center;
            color: #999;
        }}
        
        /* Features List */
        .features-list {{
            background: white;
            border-radius: 12px;
            padding: 32px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 32px;
        }}
        
        .features-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 16px;
            margin-top: 24px;
        }}
        
        .feature-item {{
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            border-left: 4px solid #0066cc;
        }}
        
        .feature-title {{
            font-weight: 600;
            margin-bottom: 8px;
            color: #1a1a1a;
        }}
        
        .feature-description {{
            color: #666;
            font-size: 0.95rem;
        }}
        
        /* Responsive */
        @media (max-width: 768px) {{
            .component-title {{
                font-size: 2rem;
            }}
            
            .info-grid {{
                grid-template-columns: 1fr;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <a href="../index.html" class="back-link">
            ← Back to Design System
        </a>
        
        <!-- Component Header -->
        <div class="component-header">
            <span class="component-id">{component['id']}</span>
            <h1 class="component-title">{component['name']}</h1>
            <p class="component-description">
                {component['description']}
            </p>
            
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Category</span>
                    <span class="info-value">{component['category']}</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Status</span>
                    <span class="info-value"><span class="status-badge">{component['status']}</span></span>
                </div>
                <div class="info-item">
                    <span class="info-label">User Type</span>
                    <span class="info-value">{component['user_type']}</span>
                </div>
                <div class="info-item">
                    <span class="info-label">Scenario</span>
                    <span class="info-value">{component['scenario']}</span>
                </div>
            </div>
        </div>
        
        <!-- Design Section -->
        <div class="design-section">
            <div class="section-header">
                <span class="section-icon">🎨</span>
                <h2 class="section-title">Design Preview</h2>
            </div>
            
            <div class="design-preview">
                <div class="design-placeholder">
                    <p>📐 {component['name']} design mockup will be placed here</p>
                    <p style="font-size: 0.9rem; margin-top: 8px;">Upload to: /design-system/mockups/{component['filename'].replace('.html', '.png')}</p>
                </div>
            </div>
        </div>
        
        <!-- Key Features -->
        <div class="features-list">
            <div class="section-header">
                <span class="section-icon">⚡</span>
                <h2 class="section-title">Key Features</h2>
            </div>
            
            <div class="features-grid">"""
    
    # Add features
    for feature in component['features']:
        template += f"""
                <div class="feature-item">
                    <h3 class="feature-title">{feature['title']}</h3>
                    <p class="feature-description">{feature['desc']}</p>
                </div>"""
    
    template += """
            </div>
        </div>
    </div>
</body>
</html>"""
    
    return template

def main():
    """Create all component files."""
    components_dir = Path("/Users/spitexbemeda/Documents/Bemeda Personal Page/docs/site/design-system/components")
    components_dir.mkdir(exist_ok=True)
    
    print(f"Creating {len(components)} UI component files...")
    
    for component in components:
        file_path = components_dir / component['filename']
        content = create_component_file(component)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Created: {component['id']} - {component['name']}")
    
    print(f"\nCompleted! Created {len(components)} component files in {components_dir}")

if __name__ == "__main__":
    main()