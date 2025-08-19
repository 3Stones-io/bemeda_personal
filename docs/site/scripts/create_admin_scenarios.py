#!/usr/bin/env python3
"""
Create the remaining admin scenario pages (S2, S3, S4).
"""

from pathlib import Path

# Define the scenarios
scenarios = [
    {
        "id": "ADMIN-S2",
        "title": "User Support & Query Management",
        "icon": "🎫",
        "color": "#28a745",
        "description": "Handle user support tickets, respond to questions from healthcare organizations and professionals, manage technical assistance, and ensure timely resolution of user issues.",
        "complexity": "Medium",
        "users": "Support Team",
        "priority": "High",
        "frequency": "Continuous",
        "participants": [
            {
                "name": "Support Specialist",
                "icon": "🎧",
                "role": "First-line user assistance and issue resolution",
                "tasks": [
                    "Receive and triage incoming support tickets",
                    "Respond to user questions via multiple channels",
                    "Escalate complex technical issues to development team",
                    "Update knowledge base with common solutions",
                    "Track response times and customer satisfaction"
                ],
                "ui_elements": [
                    {"id": "UI-021", "name": "Ticket Dashboard", "status": "Ready"},
                    {"id": "UI-022", "name": "Chat Interface", "status": "Progress"},
                    {"id": "UI-023", "name": "Knowledge Base", "status": "Progress"},
                    {"id": "UI-024", "name": "Response Templates", "status": "Pending"}
                ]
            },
            {
                "name": "Support Manager",
                "icon": "📊",
                "role": "Team oversight and performance monitoring",
                "tasks": [
                    "Monitor team performance and SLA adherence",
                    "Generate support analytics and reports",
                    "Manage escalations and complex cases",
                    "Coordinate with product team for feature requests"
                ],
                "ui_elements": [
                    {"id": "UI-025", "name": "Team Analytics", "status": "Progress"},
                    {"id": "UI-026", "name": "SLA Monitor", "status": "Pending"},
                    {"id": "UI-027", "name": "Escalation Board", "status": "Ready"},
                    {"id": "UI-028", "name": "Performance Reports", "status": "Ready"}
                ]
            }
        ]
    },
    {
        "id": "ADMIN-S3",
        "title": "Content & Policy Management",
        "icon": "📝",
        "color": "#dc3545",
        "description": "Manage platform policies, compliance requirements, certification standards, regulatory content for Swiss healthcare, and ensure all content meets legal and professional standards.",
        "complexity": "High",
        "users": "Compliance Team",
        "priority": "Critical",
        "frequency": "Weekly",
        "participants": [
            {
                "name": "Compliance Officer",
                "icon": "⚖️",
                "role": "Regulatory compliance and policy management",
                "tasks": [
                    "Review and update platform policies and terms",
                    "Monitor regulatory changes in Swiss healthcare",
                    "Ensure GDPR and data protection compliance",
                    "Manage certification requirement updates",
                    "Coordinate with legal team on policy changes"
                ],
                "ui_elements": [
                    {"id": "UI-029", "name": "Policy Editor", "status": "Ready"},
                    {"id": "UI-030", "name": "Compliance Tracker", "status": "Progress"},
                    {"id": "UI-031", "name": "Regulatory Monitor", "status": "Progress"},
                    {"id": "UI-032", "name": "Audit Trail", "status": "Pending"}
                ]
            },
            {
                "name": "Content Manager",
                "icon": "📋",
                "role": "Content creation, review, and publication",
                "tasks": [
                    "Create and update platform documentation",
                    "Manage certification and training content",
                    "Review user-generated content for compliance",
                    "Coordinate content localization for German/French"
                ],
                "ui_elements": [
                    {"id": "UI-033", "name": "Content CMS", "status": "Ready"},
                    {"id": "UI-034", "name": "Review Workflow", "status": "Progress"},
                    {"id": "UI-035", "name": "Translation Manager", "status": "Pending"},
                    {"id": "UI-036", "name": "Publishing Tools", "status": "Ready"}
                ]
            }
        ]
    },
    {
        "id": "ADMIN-S4", 
        "title": "System Configuration & Settings",
        "icon": "⚙️",
        "color": "#6f42c1",
        "description": "Configure platform settings, manage feature toggles, handle third-party integrations, control regional configurations, and maintain system security settings.",
        "complexity": "High",
        "users": "Tech Team",
        "priority": "Medium",
        "frequency": "As Needed",
        "participants": [
            {
                "name": "DevOps Engineer",
                "icon": "🔧",
                "role": "System configuration and infrastructure management",
                "tasks": [
                    "Configure platform settings and parameters",
                    "Manage feature flags and rollout controls",
                    "Monitor system integrations and APIs",
                    "Handle environment configuration changes",
                    "Maintain security and access controls"
                ],
                "ui_elements": [
                    {"id": "UI-037", "name": "Config Manager", "status": "Ready"},
                    {"id": "UI-038", "name": "Feature Flags", "status": "Progress"},
                    {"id": "UI-039", "name": "Integration Hub", "status": "Progress"},
                    {"id": "UI-040", "name": "Security Console", "status": "Pending"}
                ]
            },
            {
                "name": "Integration Specialist",
                "icon": "🔌",
                "role": "Third-party integrations and API management",
                "tasks": [
                    "Set up and configure third-party integrations",
                    "Monitor API performance and usage limits",
                    "Manage authentication and security tokens",
                    "Troubleshoot integration issues and failures"
                ],
                "ui_elements": [
                    {"id": "UI-041", "name": "API Dashboard", "status": "Ready"},
                    {"id": "UI-042", "name": "Integration Wizard", "status": "Pending"},
                    {"id": "UI-043", "name": "Token Manager", "status": "Progress"},
                    {"id": "UI-044", "name": "Monitoring Tools", "status": "Ready"}
                ]
            }
        ]
    }
]

def create_scenario_page(scenario):
    """Create a scenario page based on the template."""
    
    participants_html = ""
    for i, participant in enumerate(scenario["participants"]):
        ui_elements_html = ""
        for ui in participant["ui_elements"]:
            ui_elements_html += f'''
                            <a href="../../design-system/components/{ui["id"].lower()}-{ui["name"].lower().replace(" ", "-")}.html" class="ui-element">
                                <div class="ui-element-id">{ui["id"]}</div>
                                <div class="ui-element-name">{ui["name"]}</div>
                                <div class="ui-element-status">{ui["status"]}</div>
                            </a>'''
        
        tasks_html = ""
        for j, task in enumerate(participant["tasks"], 1):
            tasks_html += f'''
                            <a href="p{i+1}/s{j}.html" class="process-step">
                                <div class="step-number">{j}</div>
                                <div class="step-text">{task}</div>
                            </a>'''
        
        participants_html += f'''
                <!-- {participant["name"]} -->
                <div class="participant-section">
                    <div class="participant-header">
                        <span class="participant-icon">{participant["icon"]}</span>
                        <div>
                            <h2 class="participant-name">{participant["name"]}</h2>
                            <p class="participant-role">{participant["role"]}</p>
                        </div>
                    </div>
                    
                    <div class="subsection">
                        <h3 class="subsection-title">📋 Key Responsibilities</h3>
                        <div class="process-steps">{tasks_html}
                        </div>
                    </div>
                    
                    <!-- UI Implementation -->
                    <div class="subsection">
                        <h3 class="subsection-title">🎨 UI Elements</h3>
                        <div class="ui-elements">{ui_elements_html}
                        </div>
                    </div>
                </div>'''
    
    # Determine active navigation highlighting
    nav_highlight = ""
    if scenario["id"] == "ADMIN-S2":
        nav_highlight = '<a href="/site/sitemap/admin/s2/index.html" data-i18n="nav.admin-support" style="background: #d4edda;">User Support</a>'
    elif scenario["id"] == "ADMIN-S3":
        nav_highlight = '<a href="/site/sitemap/admin/s3/index.html" data-i18n="nav.admin-content" style="background: #f8d7da;">Content Management</a>'
    elif scenario["id"] == "ADMIN-S4":
        nav_highlight = '<a href="/site/sitemap/admin/s4/index.html" data-i18n="nav.admin-settings" style="background: #e2e3e5;">System Settings</a>'
    
    nav_dropdown = f'''
                        <a href="/site/sitemap/admin/s1/index.html" data-i18n="nav.admin-dashboard">Platform Dashboard</a>
                        <a href="/site/sitemap/admin/s2/index.html" data-i18n="nav.admin-support">User Support</a>
                        <a href="/site/sitemap/admin/s3/index.html" data-i18n="nav.admin-content">Content Management</a>
                        <a href="/site/sitemap/admin/s4/index.html" data-i18n="nav.admin-settings">System Settings</a>'''
    
    if nav_highlight:
        nav_dropdown = nav_dropdown.replace(f'<a href="/site/sitemap/admin/{scenario["id"].lower().replace("admin-", "")}/index.html"', nav_highlight.replace('<a href="/site/sitemap/admin/', '<a href="/site/sitemap/admin/').replace('data-i18n="nav.admin-', 'data-i18n="nav.admin-').split('"')[0] + '"')

    template = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{scenario["id"]}: {scenario["title"]} - Bemeda Admin</title>
    <link rel="stylesheet" href="../../../assets/global/css/language-switcher.css">
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
        
        /* Top Navigation */
        .top-nav {{
            background: white;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            padding: 0;
            margin-bottom: 20px;
            border-radius: 8px;
            overflow: visible;
        }}
        
        .nav-list {{
            display: flex;
            list-style: none;
            margin: 0;
            padding: 0;
        }}
        
        .nav-item {{
            flex: 1;
            position: relative;
        }}
        
        .nav-link {{
            display: block;
            padding: 16px 20px;
            text-decoration: none;
            color: #666;
            border-right: 1px solid #eee;
            text-align: center;
            transition: all 0.2s;
        }}
        
        .nav-link:hover {{
            background: #f8f9fa;
            color: #0066cc;
        }}
        
        .nav-link.active {{
            background: #0066cc;
            color: white;
        }}
        
        .nav-item:last-child .nav-link {{
            border-right: none;
        }}
        
        /* Dropdown Styles */
        .dropdown {{
            position: relative;
        }}
        
        .dropdown-content {{
            display: none;
            position: absolute;
            top: 100%;
            left: 0;
            right: 0;
            background: white;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            border-radius: 0 0 8px 8px;
            z-index: 1000;
            min-width: 200px;
        }}
        
        .dropdown:hover .dropdown-content {{
            display: block;
        }}
        
        .dropdown-content a {{
            display: block;
            padding: 12px 20px;
            text-decoration: none;
            color: #666;
            border-bottom: 1px solid #eee;
            transition: background 0.2s;
            white-space: nowrap;
        }}
        
        .dropdown-content a:last-child {{
            border-bottom: none;
        }}
        
        .dropdown-content a:hover {{
            background: #f8f9fa;
            color: #0066cc;
        }}
        
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
        
        /* Scenario Header */
        .scenario-header {{
            background: white;
            border-radius: 12px;
            padding: 32px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            margin-bottom: 32px;
            border-left: 4px solid {scenario["color"]};
        }}
        
        .scenario-title-section {{
            display: flex;
            align-items: center;
            gap: 20px;
            margin-bottom: 20px;
        }}
        
        .scenario-icon {{
            font-size: 4rem;
            background: {scenario["color"]}20;
            padding: 20px;
            border-radius: 16px;
            border: 2px solid {scenario["color"]}40;
        }}
        
        .scenario-id {{
            background: {scenario["color"]};
            color: white;
            padding: 8px 20px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 1.1rem;
            margin-bottom: 12px;
            display: inline-block;
        }}
        
        .scenario-title {{
            font-size: 2.5rem;
            font-weight: 600;
            color: #1a1a1a;
        }}
        
        .scenario-description {{
            font-size: 1.2rem;
            color: #666;
            margin-bottom: 24px;
        }}
        
        .scenario-meta {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 16px;
        }}
        
        .meta-item {{
            text-align: center;
            padding: 16px;
            background: #f8f9fa;
            border-radius: 8px;
        }}
        
        .meta-label {{
            font-size: 0.9rem;
            color: #666;
            margin-bottom: 4px;
        }}
        
        .meta-value {{
            font-weight: 600;
            color: #1a1a1a;
        }}
        
        /* Participants Section */
        .participants-section {{
            margin-bottom: 40px;
        }}
        
        .participants-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 32px;
        }}
        
        .participant-section {{
            background: white;
            border-radius: 12px;
            padding: 32px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }}
        
        .participant-header {{
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 24px;
            padding-bottom: 16px;
            border-bottom: 2px solid #f0f0f0;
        }}
        
        .participant-icon {{
            font-size: 2.5rem;
            background: #f0f8ff;
            padding: 16px;
            border-radius: 12px;
            border: 2px solid #e0efff;
        }}
        
        .participant-name {{
            font-size: 1.5rem;
            font-weight: 600;
            color: #1a1a1a;
        }}
        
        .participant-role {{
            color: #666;
            font-size: 1rem;
        }}
        
        .subsection {{
            margin-bottom: 24px;
        }}
        
        .subsection-title {{
            font-size: 1.2rem;
            font-weight: 600;
            margin-bottom: 16px;
            color: #1a1a1a;
            display: flex;
            align-items: center;
            gap: 8px;
        }}
        
        /* Process Steps */
        .process-steps {{
            display: grid;
            gap: 12px;
        }}
        
        .process-step {{
            display: flex;
            align-items: center;
            gap: 16px;
            padding: 16px;
            background: #f8f9fa;
            border-radius: 8px;
            border-left: 4px solid {scenario["color"]};
            transition: all 0.2s;
            text-decoration: none;
            color: inherit;
        }}
        
        .process-step:hover {{
            background: {scenario["color"]}20;
            transform: translateX(4px);
        }}
        
        .step-number {{
            background: {scenario["color"]};
            color: white;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            font-size: 0.9rem;
        }}
        
        .step-text {{
            flex: 1;
            font-weight: 500;
        }}
        
        /* UI Elements */
        .ui-elements {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 12px;
        }}
        
        .ui-element {{
            padding: 12px;
            background: #f8f9fa;
            border-radius: 8px;
            text-align: center;
            border: 2px solid transparent;
            transition: all 0.2s;
            text-decoration: none;
            color: inherit;
            display: block;
        }}
        
        .ui-element:hover {{
            border-color: {scenario["color"]};
            background: {scenario["color"]}20;
            transform: translateY(-1px);
            box-shadow: 0 2px 8px {scenario["color"]}40;
        }}
        
        .ui-element-id {{
            background: {scenario["color"]};
            color: white;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 0.8rem;
            font-weight: 600;
            margin-bottom: 4px;
        }}
        
        .ui-element-name {{
            font-weight: 600;
            margin-bottom: 4px;
            color: #1a1a1a;
        }}
        
        .ui-element-status {{
            font-size: 0.8rem;
            color: #666;
        }}
        
        /* Quick Links */
        .issues-section {{
            background: white;
            border-radius: 12px;
            padding: 32px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }}
        
        .issues-header h2 {{
            color: #1a1a1a;
            margin-bottom: 24px;
        }}
        
        /* Responsive */
        @media (max-width: 1024px) {{
            .participants-grid {{
                grid-template-columns: 1fr;
            }}
        }}
        
        @media (max-width: 768px) {{
            .scenario-title-section {{
                flex-direction: column;
                text-align: center;
            }}
            
            .scenario-title {{
                font-size: 2rem;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <!-- Top Navigation -->
        <nav class="top-nav">
            <ul class="nav-list">
                <li class="nav-item">
                    <a href="/index.html" class="nav-link" data-i18n="nav.index">Index</a>
                </li>
                <li class="nav-item">
                    <a href="/site/sitemap/job/index.html" class="nav-link" data-i18n="nav.job">JOB</a>
                </li>
                <li class="nav-item dropdown">
                    <a href="/site/sitemap/tmp/index.html" class="nav-link" data-i18n="nav.tmp">TMP</a>
                    <div class="dropdown-content">
                        <a href="/site/sitemap/tmp/temporary/index.html" data-i18n="nav.tmp-temporary">TMP-Temporary</a>
                        <a href="/site/sitemap/tmp/tryhire/index.html" data-i18n="nav.tmp-tryhire">TMP & Hire</a>
                        <a href="/site/sitemap/tmp/pool/index.html" data-i18n="nav.tmp-pool">TMP-Pool</a>
                    </div>
                </li>
                <li class="nav-item">
                    <a href="/site/sitemap/table/index.html" class="nav-link">Table</a>
                </li>
                <li class="nav-item dropdown">
                    <a href="/site/sitemap/admin/index.html" class="nav-link active" data-i18n="nav.admin">Admin</a>
                    <div class="dropdown-content">{nav_dropdown}
                    </div>
                </li>
            </ul>
        </nav>
        
        <a href="../index.html" class="back-link">
            ← Back to Admin Portal
        </a>
        
        <!-- Scenario Header -->
        <div class="scenario-header">
            <div class="scenario-title-section">
                <div class="scenario-icon">{scenario["icon"]}</div>
                <div>
                    <span class="scenario-id">{scenario["id"]}</span>
                    <h1 class="scenario-title">{scenario["title"]}</h1>
                </div>
            </div>
            <p class="scenario-description">
                {scenario["description"]}
            </p>
            <div class="scenario-meta">
                <div class="meta-item">
                    <div class="meta-label">Complexity</div>
                    <div class="meta-value">{scenario["complexity"]}</div>
                </div>
                <div class="meta-item">
                    <div class="meta-label">Primary Users</div>
                    <div class="meta-value">{scenario["users"]}</div>
                </div>
                <div class="meta-item">
                    <div class="meta-label">Priority</div>
                    <div class="meta-value">{scenario["priority"]}</div>
                </div>
                <div class="meta-item">
                    <div class="meta-label">Frequency</div>
                    <div class="meta-value">{scenario["frequency"]}</div>
                </div>
            </div>
        </div>
        
        <!-- Participants Section -->
        <div class="participants-section">
            <div class="participants-grid">{participants_html}
            </div>
        </div>
        
        <!-- Quick Links Section -->
        <div class="issues-section">
            <div class="issues-header">
                <h2>🔗 Quick Links</h2>
            </div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 16px; padding: 20px 0;">
                <a href="/site/design-system/index.html" style="text-decoration: none;">
                    <div class="ui-element" style="cursor: pointer; transition: all 0.2s;">
                        <div class="ui-element-name">📋 Design System</div>
                        <div class="ui-element-status">Component Documentation</div>
                    </div>
                </a>
                <a href="../index.html" style="text-decoration: none;">
                    <div class="ui-element" style="cursor: pointer; transition: all 0.2s;">
                        <div class="ui-element-name">🛡️ Admin Portal</div>
                        <div class="ui-element-status">All Admin Scenarios</div>
                    </div>
                </a>
                <a href="/site/sitemap/table/index.html" style="text-decoration: none;">
                    <div class="ui-element" style="cursor: pointer; transition: all 0.2s;">
                        <div class="ui-element-name">📊 Table View</div>
                        <div class="ui-element-status">All Platform Scenarios</div>
                    </div>
                </a>
                <a href="/index.html" style="text-decoration: none;">
                    <div class="ui-element" style="cursor: pointer; transition: all 0.2s;">
                        <div class="ui-element-name">🏠 Main Index</div>
                        <div class="ui-element-status">Platform Overview</div>
                    </div>
                </a>
            </div>
        </div>
    </div>
    
    <script src="../../../assets/global/js/language-switcher.js"></script>
</body>
</html>'''
    
    return template

def main():
    """Create all admin scenario pages."""
    base_path = Path("/Users/spitexbemeda/Documents/Bemeda Personal Page/docs/site/sitemap/admin")
    
    for scenario in scenarios:
        scenario_num = scenario["id"].split("-")[1].lower()  # s2, s3, s4
        file_path = base_path / scenario_num / "index.html"
        
        content = create_scenario_page(scenario)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"Created: {scenario['id']} - {scenario['title']}")
    
    print(f"\nCompleted! Created {len(scenarios)} admin scenario pages.")

if __name__ == "__main__":
    main()