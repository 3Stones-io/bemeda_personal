# Bemeda Platform Documentation Structure - Conceptual Overview

## 🎯 **Simplified Structure Overview**

```mermaid
graph TB
    %% Main Entry Points
    MAIN[📄 Main Dashboard<br/>docs/index.html]
    UNIFIED[📊 Unified Feature Table<br/>Single Source of Truth]
    
    %% Example Features (showing just 2 as examples)
    subgraph "🎯 Feature Examples"
        F001[🔍 F001 - Job Search & Discovery<br/>features/job-search-discovery/]
        F002[👤 F002 - User Profiles<br/>features/user-profiles/]
    end
    
    %% Participant Perspectives (showing how each feature has 4 perspectives)
    subgraph "👥 Participant Perspectives (Per Feature)"
        B001[📋 Business Analysis<br/>Nicole]
        D001[🎨 UX/UI Design<br/>Oghogho]
        T001[🐛 Testing & QA<br/>Dejan]
        I001[⚙️ Technical Implementation<br/>Almir]
    end
    
    %% Participant Domains (showing specialized work areas)
    subgraph "🏢 Participant Domains"
        SCENARIOS[📋 Scenarios & Workflows<br/>participants/scenarios/<br/>Nicole's Domain]
        UXUI[🎨 UX/UI & Design System<br/>participants/ux-ui/<br/>Oghogho's Domain]
        TESTING[🐛 Testing & QA<br/>participants/testing/<br/>Dejan's Domain]
        FEATURES[⚙️ Features & Implementation<br/>participants/features/<br/>Almir's Domain]
    end
    
    %% Navigation Flow
    MAIN --> UNIFIED
    UNIFIED --> F001
    UNIFIED --> F002
    
    %% Feature to Participant Perspectives
    F001 --> B001
    F001 --> D001
    F001 --> T001
    F001 --> I001
    
    F002 --> B001
    F002 --> D001
    F002 --> T001
    F002 --> I001
    
    %% Participant Domains
    B001 --> SCENARIOS
    D001 --> UXUI
    T001 --> TESTING
    I001 --> FEATURES
    
    %% Feature Dependencies
    F001 -.-> F002
    
    %% Styling
    classDef featureNode fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef participantNode fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef domainNode fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef entryNode fill:#fce4ec,stroke:#880e4f,stroke-width:3px
    
    class F001,F002 featureNode
    class B001,D001,T001,I001 participantNode
    class SCENARIOS,UXUI,TESTING,FEATURES domainNode
    class MAIN,UNIFIED entryNode
```

## 📋 **How Scenarios, User Cases, and Features Connect**

```mermaid
graph LR
    subgraph "📋 Business Analysis Layer (Nicole)"
        SCENARIO1[📖 Scenario: Job Seeker Journey<br/>S001 - User finds and applies to job]
        USERSTORY1[👤 User Story: US001<br/>"As a job seeker, I want to search for jobs<br/>so that I can find relevant opportunities"]
        USECASE1[🎯 Use Case: UC001<br/>"Search Jobs with Filters"]
    end
    
    subgraph "🎨 Design Layer (Oghogho)"
        mess<br/>UF001 - Search interaction flow]
    end
    
    subgraph "🐛 Testing Layer (Dejan)"
        TESTCASE1[🧪 Test Case: TC001<br/>"Search functionality with filters"]
        ACCEPTANCE1[✅ Acceptance Criteria<br/>AC001 - Search requirements]
    end
    
    subgraph "⚙️ Technical Layer (Almir)"
        SPEC1[📋 Technical Spec: TS001<br/>"Search API specification"]
        API1[🔌 API: Search Endpoints<br/>API001 - /api/jobs/search]
        DB1[🗄️ Database: Job Schema<br/>DB001 - jobs table]
    end
    
    %% How they connect to the feature
    subgraph "🎯 Feature: F001 - Job Search & Discovery"
        FEATURE1[🔍 Job Search Feature<br/>All components working together]
    end
    
    %% Business Analysis connections
    SCENARIO1 --> USERSTORY1
    USERSTORY1 --> USECASE1
    USECASE1 --> FEATURE1
    
    %% Design connections
    USECASE1 --> MOCKUP1
    MOCKUP1 --> COMPONENT1
    COMPONENT1 --> USERFLOW1
    USERFLOW1 --> FEATURE1
    
    %% Testing connections
    USECASE1 --> TESTCASE1
    TESTCASE1 --> ACCEPTANCE1
    ACCEPTANCE1 --> FEATURE1
    
    %% Technical connections
    USECASE1 --> SPEC1
    SPEC1 --> API1
    API1 --> DB1
    DB1 --> FEATURE1
    
    %% Cross-layer connections
    COMPONENT1 --> TESTCASE1
    API1 --> TESTCASE1
    USERFLOW1 --> ACCEPTANCE1
    
    %% Styling
    classDef businessNode fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef designNode fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef testingNode fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef technicalNode fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef featureNode fill:#fff3e0,stroke:#e65100,stroke-width:3px
    
    class SCENARIO1,USERSTORY1,USECASE1 businessNode
    class MOCKUP1,COMPONENT1,USERFLOW1 designNode
    class TESTCASE1,ACCEPTANCE1 testingNode
    class SPEC1,API1,DB1 technicalNode
    class FEATURE1 featureNode
```

## 🔗 **Numbering System and Dependencies**

```mermaid
graph TD
    subgraph "📋 Business Analysis Numbering"
        S001[📖 S001 - Job Seeker Journey Scenario]
        US001[👤 US001 - Search Jobs User Story]
        UC001[🎯 UC001 - Search with Filters Use Case]
    end
    
    subgraph "🎨 Design Numbering"
        M001[📱 M001 - Search Page Mockup]
        C001[🧩 C001 - Filter Component]
        UF001[🔄 UF001 - Search User Flow]
    end
    
    subgraph "🐛 Testing Numbering"
        TC001[🧪 TC001 - Search Test Case]
        AC001[✅ AC001 - Search Acceptance Criteria]
    end
    
    subgraph "⚙️ Technical Numbering"
        TS001[📋 TS001 - Search API Spec]
        API001[🔌 API001 - /api/jobs/search]
        DB001[🗄️ DB001 - Jobs Table Schema]
    end
    
    subgraph "🎯 Feature Integration"
        F001[🔍 F001 - Job Search Feature<br/>Integrates all numbered components]
    end
    
    %% Numbering relationships
    S001 --> US001
    US001 --> UC001
    UC001 --> M001
    UC001 --> C001
    UC001 --> UF001
    UC001 --> TC001
    UC001 --> TS001
    
    M001 --> C001
    C001 --> UF001
    TS001 --> API001
    API001 --> DB001
    
    TC001 --> AC001
    UF001 --> AC001
    
    %% All connect to the feature
    UC001 --> F001
    UF001 --> F001
    AC001 --> F001
    API001 --> F001
    
    %% Styling
    classDef businessNode fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef designNode fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef testingNode fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef technicalNode fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef featureNode fill:#fff3e0,stroke:#e65100,stroke-width:3px
    
    class S001,US001,UC001 businessNode
    class M001,C001,UF001 designNode
    class TC001,AC001 testingNode
    class TS001,API001,DB001 technicalNode
    class F001 featureNode
```

## 📁 **File Structure Example (One Feature)**

```mermaid
graph TB
    subgraph "🎯 F001 - Job Search & Discovery"
        F001_ROOT[features/job-search-discovery/]
        
        subgraph "📋 Business Analysis"
            B001_DIR[business/]
            B001_SCENARIO[scenarios.html<br/>S001 - Job Seeker Journey]
            B001_USERSTORY[user-stories.html<br/>US001 - Search Jobs]
            B001_USECASE[use-cases.html<br/>UC001 - Search with Filters]
        end
        
        subgraph "🎨 UX/UI Design"
            D001_DIR[design/]
            D001_MOCKUP[mockups.html<br/>M001 - Search Page]
            D001_COMPONENT[components.html<br/>C001 - Filter Component]
            D001_USERFLOW[user-flows.html<br/>UF001 - Search Flow]
        end
        
        subgraph "🐛 Testing & QA"
            T001_DIR[testing/]
            T001_TESTCASE[test-cases.html<br/>TC001 - Search Tests]
            T001_ACCEPTANCE[acceptance-criteria.html<br/>AC001 - Search Criteria]
        end
        
        subgraph "⚙️ Technical Implementation"
            I001_DIR[technical/]
            I001_SPEC[specifications.html<br/>TS001 - Search API Spec]
            I001_API[api-docs.html<br/>API001 - Search Endpoints]
            I001_DATABASE[database-schema.html<br/>DB001 - Jobs Schema]
        end
    end
    
    %% Structure relationships
    F001_ROOT --> B001_DIR
    F001_ROOT --> D001_DIR
    F001_ROOT --> T001_DIR
    F001_ROOT --> I001_DIR
    
    B001_DIR --> B001_SCENARIO
    B001_DIR --> B001_USERSTORY
    B001_DIR --> B001_USECASE
    
    D001_DIR --> D001_MOCKUP
    D001_DIR --> D001_COMPONENT
    D001_DIR --> D001_USERFLOW
    
    T001_DIR --> T001_TESTCASE
    T001_DIR --> T001_ACCEPTANCE
    
    I001_DIR --> I001_SPEC
    I001_DIR --> I001_API
    I001_DIR --> I001_DATABASE
    
    %% Cross-dependencies
    B001_USECASE -.-> D001_MOCKUP
    B001_USECASE -.-> T001_TESTCASE
    B001_USECASE -.-> I001_SPEC
    D001_COMPONENT -.-> T001_TESTCASE
    I001_API -.-> T001_TESTCASE
    
    %% Styling
    classDef featureRoot fill:#e1f5fe,stroke:#01579b,stroke-width:3px
    classDef businessNode fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef designNode fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef testingNode fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef technicalNode fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    
    class F001_ROOT featureRoot
    class B001_DIR,B001_SCENARIO,B001_USERSTORY,B001_USECASE businessNode
    class D001_DIR,D001_MOCKUP,D001_COMPONENT,D001_USERFLOW designNode
    class T001_DIR,T001_TESTCASE,T001_ACCEPTANCE testingNode
    class I001_DIR,I001_SPEC,I001_API,I001_DATABASE technicalNode
```

## 🔄 **How Scenarios Drive Everything**

```mermaid
graph LR
    subgraph "📖 Scenario: S001 - Job Seeker Journey"
        SCENARIO[User finds and applies to job<br/>Complete end-to-end process]
    end
    
    subgraph "👤 User Stories (from Scenario)"
        US001[US001 - Search for jobs]
        US002[US002 - Apply to job]
        US003[US003 - Track application]
    end
    
    subgraph "🎯 Use Cases (from User Stories)"
        UC001[UC001 - Search with filters]
        UC002[UC002 - Submit application]
        UC003[UC003 - View application status]
    end
    
    subgraph "🎨 Design (from Use Cases)"
        M001[M001 - Search page mockup]
        M002[M002 - Application form mockup]
        M003[M003 - Status page mockup]
    end
    
    subgraph "⚙️ Technical (from Use Cases)"
        API001[API001 - Search endpoints]
        API002[API002 - Application endpoints]
        API003[API003 - Status endpoints]
    end
    
    subgraph "🐛 Testing (from Use Cases)"
        TC001[TC001 - Search tests]
        TC002[TC002 - Application tests]
        TC003[TC003 - Status tests]
    end
    
    %% Scenario drives everything
    SCENARIO --> US001
    SCENARIO --> US002
    SCENARIO --> US003
    
    US001 --> UC001
    US002 --> UC002
    US003 --> UC003
    
    UC001 --> M001
    UC002 --> M002
    UC003 --> M003
    
    UC001 --> API001
    UC002 --> API002
    UC003 --> API003
    
    UC001 --> TC001
    UC002 --> TC002
    UC003 --> TC003
    
    %% Cross-dependencies
    M001 -.-> TC001
    API001 -.-> TC001
    M002 -.-> TC002
    API002 -.-> TC002
    
    %% Styling
    classDef scenarioNode fill:#fff3e0,stroke:#e65100,stroke-width:3px
    classDef userStoryNode fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef useCaseNode fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef designNode fill:#f3e5f5,stroke:#7b1fa2,stroke-width:1px
    classDef technicalNode fill:#e8f5e8,stroke:#388e3c,stroke-width:1px
    classDef testingNode fill:#ffebee,stroke:#d32f2f,stroke-width:1px
    
    class SCENARIO scenarioNode
    class US001,US002,US003 userStoryNode
    class UC001,UC002,UC003 useCaseNode
    class M001,M002,M003 designNode
    class API001,API002,API003 technicalNode
    class TC001,TC002,TC003 testingNode
```

---

## 📋 **Key Insights for Documentation Structure**

### **🎯 How Scenarios Drive Everything**
1. **Scenario (S001)** → **User Stories (US001, US002, US003)** → **Use Cases (UC001, UC002, UC003)**
2. **Use Cases** drive **Design**, **Technical**, and **Testing** work
3. **Everything connects back to the Feature (F001)**

### **🔢 Numbering System**
- **S###** - Scenarios (S001, S002, etc.)
- **US###** - User Stories (US001, US002, etc.)
- **UC###** - Use Cases (UC001, UC002, etc.)
- **M###** - Mockups (M001, M002, etc.)
- **C###** - Components (C001, C002, etc.)
- **UF###** - User Flows (UF001, UF002, etc.)
- **TC###** - Test Cases (TC001, TC002, etc.)
- **AC###** - Acceptance Criteria (AC001, AC002, etc.)
- **TS###** - Technical Specifications (TS001, TS002, etc.)
- **API###** - API Endpoints (API001, API002, etc.)
- **DB###** - Database Schemas (DB001, DB002, etc.)
- **F###** - Features (F001, F002, etc.)

### **🔗 Dependencies**
- **Scenarios** are the foundation that drives everything
- **User Stories** break down scenarios into actionable items
- **Use Cases** define specific interactions
- **Design, Technical, and Testing** all derive from use cases
- **Features** integrate all the numbered components

### **📁 File Organization**
- Each **feature** has its own directory with 4 **participant perspectives**
- Each **perspective** contains numbered **artifacts** (scenarios, mockups, tests, etc.)
- **Cross-references** connect related artifacts across perspectives
- **Unified table** provides overview of all features and their status

This structure ensures that **every piece of documentation is traceable** back to the original scenario and **all team members can see how their work connects** to the overall feature goals.

---

## 🔍 **Real-World Example: JOB S1 Scenario Analysis**

Based on actual analysis of the JOB S1 implementation in the docs/site/sitemap/job/s1/ structure, here's how scenarios, user stories, and use cases work together:

### **📖 JOB S1: "Cold Call to Candidate Placement" - Complete Structure**

```mermaid
graph TB
    subgraph "📖 JOB S1 Scenario: Cold Call to Candidate Placement"
        
        subgraph "🎯 Use Cases (Cross-Participant Functional Requirements)"
            UC001[UC-001: Healthcare Organization Onboarding<br/>Complete client acquisition process<br/>Spans: P1-S1→S3, P3-S1→S3]
            UC002[UC-002: Healthcare Professional Recruitment<br/>Complete candidate matching process<br/>Spans: P2-S1→S3, P1-S4]  
            UC003[UC-003: Placement Coordination<br/>End-to-end placement management<br/>Spans: P1-S5→S6, P2-S4→S6, P3-S5→S6]
            UC004[UC-004: Multi-Party Communication<br/>Cross-participant interaction system<br/>Spans: Multiple steps across all participants]
        end
        
        subgraph "👤 User Stories (Individual Process Steps)"
            subgraph "P1: Organisation (🏥)"
                P1S1[s1.html: Receives cold call] 
                P1S2[s2.html: Discusses staffing needs]
                P1S3[s3.html: Agrees to publish job posting]
                P1S4[s4.html: Reviews matched candidates]
                P1S5[s5.html: Conducts interviews]
                P1S6[s6.html: Completes hiring process]
            end
            
            subgraph "P2: JobSeeker (🔍)" 
                P2S1[s1.html: Creates comprehensive profile]
                P2S2[s2.html: Receives job notification] 
                P2S3[s3.html: Reviews job and applies]
                P2S4[s4.html: Participates in interview]
                P2S5[s5.html: Receives and accepts offer]
                P2S6[s6.html: Completes onboarding]
            end
            
            subgraph "P3: Sales Team (📞)"
                P3S1[s1.html: Identifies healthcare prospect]
                P3S2[s2.html: Makes initial cold call]
                P3S3[s3.html: Presents platform benefits] 
                P3S4[s4.html: Facilitates onboarding]
                P3S5[s5.html: Monitors placement progress]
                P3S6[s6.html: Follows up for opportunities]
            end
        end
    end
    
    %% Use Cases span across multiple user stories
    UC001 --> P1S1
    UC001 --> P1S2  
    UC001 --> P1S3
    UC001 --> P3S1
    UC001 --> P3S2
    UC001 --> P3S3
    
    UC002 --> P2S1
    UC002 --> P2S2
    UC002 --> P2S3
    UC002 --> P1S4
    UC002 --> P2S4
    
    UC003 --> P3S4
    UC003 --> P3S5
    UC003 --> P1S5
    UC003 --> P1S6
    UC003 --> P2S5
    UC003 --> P2S6
    
    UC004 --> P1S2
    UC004 --> P2S3
    UC004 --> P1S4
    UC004 --> P2S4
    UC004 --> P3S4
    UC004 --> P3S5
    
    %% Styling
    classDef scenarioNode fill:#fff3e0,stroke:#e65100,stroke-width:3px
    classDef useCaseNode fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef userStoryNode fill:#f3e5f5,stroke:#4a148c,stroke-width:1px
    
    class UC001,UC002,UC003,UC004 useCaseNode
    class P1S1,P1S2,P1S3,P1S4,P1S5,P1S6,P2S1,P2S2,P2S3,P2S4,P2S5,P2S6,P3S1,P3S2,P3S3,P3S4,P3S5,P3S6 userStoryNode
```

### **🔢 JOB S1 Quantified Structure**

```mermaid
graph LR
    subgraph "📊 JOB S1 Structure Breakdown"
        SCENARIO[📖 1 Scenario<br/>JOB S1: Cold Call to Placement]
        USECASES[🎯 4 Use Cases<br/>Cross-participant functions]
        PARTICIPANTS[👥 3 Participant Groups<br/>P1, P2, P3]
        USERSTORIES[👤 18 User Stories<br/>6 steps per participant]
    end
    
    SCENARIO --> USECASES
    SCENARIO --> PARTICIPANTS
    PARTICIPANTS --> USERSTORIES
    USECASES --> USERSTORIES
    
    classDef scenarioNode fill:#fff3e0,stroke:#e65100,stroke-width:3px
    classDef useCaseNode fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef participantNode fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef userStoryNode fill:#ffebee,stroke:#d32f2f,stroke-width:1px
    
    class SCENARIO scenarioNode
    class USECASES useCaseNode
    class PARTICIPANTS participantNode
    class USERSTORIES userStoryNode
```

---

## 📋 **Scenarios vs User Stories vs Use Cases - Definitions**

### **🔑 Key Terminology Clarification**

```mermaid
graph TB
    subgraph "📖 Business Scenario Level"
        SCENARIO[📖 Scenario<br/>Complete end-to-end business workflow<br/>Example: 'Cold Call to Candidate Placement']
    end
    
    subgraph "🎯 Functional Requirement Level"
        UC1[🎯 Use Case 1<br/>Cross-participant business function<br/>Example: 'Healthcare Organization Onboarding']
        UC2[🎯 Use Case 2<br/>Cross-participant business function<br/>Example: 'Candidate-Job Matching Engine']
        UC3[🎯 Use Case 3<br/>Cross-participant business function<br/>Example: 'Interview & Placement Process']
    end
    
    subgraph "👤 Individual Process Level"
        subgraph "P1 Journey"
            US1[👤 User Story 1<br/>Individual step in process<br/>s1.html: 'Receives cold call']
            US2[👤 User Story 2<br/>Individual step in process<br/>s2.html: 'Discusses needs']
            US3[👤 User Story 3<br/>Individual step in process<br/>s3.html: 'Posts job']
        end
        
        subgraph "P2 Journey"
            US4[👤 User Story 4<br/>Individual step in process<br/>s1.html: 'Creates profile']
            US5[👤 User Story 5<br/>Individual step in process<br/>s2.html: 'Gets notification']
            US6[👤 User Story 6<br/>Individual step in process<br/>s3.html: 'Applies to job']
        end
    end
    
    SCENARIO --> UC1
    SCENARIO --> UC2
    SCENARIO --> UC3
    
    UC1 --> US1
    UC1 --> US2
    UC1 --> US3
    UC2 --> US4
    UC2 --> US5
    UC2 --> US6
    
    classDef scenarioLevel fill:#fff3e0,stroke:#e65100,stroke-width:3px
    classDef useCaseLevel fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef userStoryLevel fill:#f3e5f5,stroke:#4a148c,stroke-width:1px
    
    class SCENARIO scenarioLevel
    class UC1,UC2,UC3 useCaseLevel
    class US1,US2,US3,US4,US5,US6 userStoryLevel
```

### **📊 Comparison Table**

| **Level** | **Scope** | **Example** | **File Location** | **Purpose** |
|-----------|-----------|-------------|-------------------|-------------|
| **📖 Scenario** | Complete business workflow | "Cold Call to Candidate Placement" | `/sitemap/job/s1/index.html` | Business context & overview |
| **🎯 Use Case** | Cross-participant function | "Healthcare Organization Onboarding" | `/features/.../business/use-cases.html` | Functional requirements |
| **👤 User Story** | Individual process step | "Organisation receives cold call" | `/sitemap/job/s1/p1/s1.html` | Detailed implementation steps |

---

## 🏗️ **Feature-Centric Documentation Structure: Scenarios → Features → Development → Use Cases**

### **Features as Central Organizing Hubs that Connect Scenarios through Development to Use Cases**

```mermaid
graph TB
    subgraph "📖 SCENARIO LAYER Business Requirements"
        SCENARIOS[📖 Business Scenarios<br/>Complete end to end workflows<br/>Example JOB S1 Cold Call to Placement]
        USERSTORIES[👤 User Stories<br/>Individual process steps<br/>Example P1-S1 P2-S1 P3-S1]
    end
    
    subgraph "🎯 FEATURE LAYER Organizational Hub"
        F001[🔍 F001 Job Search Discovery<br/>Central organizing feature<br/>Coordinates all participant work]
        F002[👤 F002 User Profiles<br/>Central organizing feature<br/>Coordinates all participant work]
        F003[📝 F003 Application Management<br/>Central organizing feature<br/>Coordinates all participant work]
        F_MORE[⚙️ F004 to F007 Additional Features<br/>Each feature as organizational hub]
    end
    
    subgraph "🔄 DEVELOPMENT LAYER Feature Specific Implementation"
        subgraph "F001 Development Team"
            F001_BIZ[📋 F001 Business<br/>Nicole<br/>JOB S1 scenario mapping<br/>Process documentation<br/>Requirements analysis]
            F001_DES[🎨 F001 Design<br/>Oghogho<br/>Search interface mockups<br/>Job listing components<br/>User flow design]
            F001_TEST[🐛 F001 Testing<br/>Dejan<br/>Search functionality tests<br/>Performance criteria<br/>Quality validation]
            F001_TECH[⚙️ F001 Technical<br/>Almir<br/>Search API development<br/>Database optimization<br/>System integration]
        end
        
        subgraph "F002 Development Team"
            F002_BIZ[📋 F002 Business]
            F002_DES[🎨 F002 Design]
            F002_TEST[🐛 F002 Testing]
            F002_TECH[⚙️ F002 Technical]
        end
        
        subgraph "F003 Development Team"
            F003_BIZ[📋 F003 Business]
            F003_DES[🎨 F003 Design] 
            F003_TEST[🐛 F003 Testing]
            F003_TECH[⚙️ F003 Technical]
        end
    end
    
    subgraph "🎯 USE CASE LAYER Cross Feature Integration"
        UC_ONBOARD[UC-001 Organization Onboarding<br/>Integrates F001 F002 F003<br/>Cross-feature functional requirement]
        UC_RECRUIT[UC-002 Professional Recruitment<br/>Integrates F001 F002 F003<br/>Cross-feature functional requirement]
        UC_PLACEMENT[UC-003 Placement Coordination<br/>Integrates F002 F003 F004<br/>Cross-feature functional requirement]
        UC_COMMUNICATION[UC-004 Multi-Party Communication<br/>Integrates F001 F002 F003 F004<br/>Cross-feature functional requirement]
    end
    
    subgraph "📁 FEATURE BASED FILE STRUCTURE"
        SCENARIO_FILES[📂 /scenarios/<br/>JOB-S1.html Maps to F001<br/>TMP-S1.html Maps to F002<br/>ADMIN-S1.html Maps to F003]
        FEATURE_FILES[📂 /features/<br/>F001 job search discovery<br/>F002 user profiles<br/>F003 application management]
        USECASE_FILES[📂 /use-cases/<br/>UC-001.html spans F001 F002 F003<br/>UC-002.html spans multiple features]
    end
    
    %% Scenarios map to Features
    SCENARIOS --> F001
    SCENARIOS --> F002
    SCENARIOS --> F003
    USERSTORIES --> F001
    USERSTORIES --> F002
    USERSTORIES --> F003
    
    %% Features organize Development work
    F001 --> F001_BIZ
    F001 --> F001_DES
    F001 --> F001_TEST
    F001 --> F001_TECH
    
    F002 --> F002_BIZ
    F002 --> F002_DES
    F002 --> F002_TEST
    F002 --> F002_TECH
    
    F003 --> F003_BIZ
    F003 --> F003_DES
    F003 --> F003_TEST
    F003 --> F003_TECH
    
    %% Features contribute to Use Cases
    F001 --> UC_ONBOARD
    F002 --> UC_ONBOARD
    F003 --> UC_ONBOARD
    
    F001 --> UC_RECRUIT
    F002 --> UC_RECRUIT
    F003 --> UC_RECRUIT
    
    F002 --> UC_PLACEMENT
    F003 --> UC_PLACEMENT
    
    F001 --> UC_COMMUNICATION
    F002 --> UC_COMMUNICATION
    F003 --> UC_COMMUNICATION
    
    %% Cross-feature collaboration in use cases
    F001_BIZ -.-> UC_ONBOARD
    F002_BIZ -.-> UC_ONBOARD
    F003_BIZ -.-> UC_ONBOARD
    
    F001_DES -.-> UC_RECRUIT
    F002_DES -.-> UC_RECRUIT
    F003_DES -.-> UC_RECRUIT
    
    %% File structure mapping
    SCENARIOS -.-> SCENARIO_FILES
    F001 -.-> FEATURE_FILES
    F002 -.-> FEATURE_FILES
    F003 -.-> FEATURE_FILES
    UC_ONBOARD -.-> USECASE_FILES
    UC_RECRUIT -.-> USECASE_FILES
    
    %% Styling
    classDef scenarioLevel fill:#fff3e0,stroke:#e65100,stroke-width:3px
    classDef featureLevel fill:#e1f5fe,stroke:#01579b,stroke-width:3px
    classDef developmentLevel fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef useCaseLevel fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef participantLevel fill:#f3e5f5,stroke:#4a148c,stroke-width:1px
    classDef fileLevel fill:#ffebee,stroke:#d32f2f,stroke-width:1px
    
    class SCENARIOS,USERSTORIES scenarioLevel
    class F001,F002,F003,F_MORE featureLevel
    class F001_BIZ,F001_DES,F001_TEST,F001_TECH,F002_BIZ,F002_DES,F002_TEST,F002_TECH,F003_BIZ,F003_DES,F003_TEST,F003_TECH participantLevel
    class UC_ONBOARD,UC_RECRUIT,UC_PLACEMENT,UC_COMMUNICATION useCaseLevel
    class SCENARIO_FILES,FEATURE_FILES,USECASE_FILES fileLevel
```

### **🔄 Development Workflow Stages**

This structure shows three distinct workflow stages:

```mermaid
graph LR
    subgraph "🏁 Stage 1: Scenario Definition"
        S1[📖 Business Scenarios<br/>Define complete workflows]
        S2[👤 User Stories<br/>Break down into steps]
    end
    
    subgraph "🔄 Stage 2: Parallel Development"
        D1[📋 Business Analysis<br/>Requirements & processes]
        D2[🎨 Design Work<br/>Interfaces & flows]
        D3[🐛 Testing Preparation<br/>Test cases & criteria]
        D4[⚙️ Technical Development<br/>APIs & implementation]
    end
    
    subgraph "🎯 Stage 3: Use Case Integration"
        U1[🎯 Use Case 1<br/>Cross-team integration]
        U2[🎯 Use Case 2<br/>Functional validation]
        U3[🎯 Use Case 3<br/>End-to-end testing]
        U4[🎯 Use Case 4<br/>Business value delivery]
    end
    
    S1 --> S2
    S2 --> D1
    S2 --> D2
    S2 --> D3
    S2 --> D4
    
    D1 --> U1
    D2 --> U1
    D3 --> U1
    D4 --> U1
    
    D1 --> U2
    D2 --> U2
    D3 --> U2
    D4 --> U2
    
    D1 --> U3
    D2 --> U3
    D3 --> U3
    D4 --> U3
    
    D1 --> U4
    D2 --> U4
    D3 --> U4
    D4 --> U4
    
    classDef stageOne fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef stageTwo fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef stageThree fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    
    class S1,S2 stageOne
    class D1,D2,D3,D4 stageTwo
    class U1,U2,U3,U4 stageThree
```

## 📁 **Proposed Enhanced File Structure**

### **Reorganized structure to support the Scenarios → Development → Use Cases workflow**

```mermaid
graph TB
    subgraph "📂 docs/site/ - Root Documentation"
        ROOT[🏠 Site Root]
        
        subgraph "📖 /scenarios/ - Business Scenario Layer"
            SCENARIO_DIR[📁 scenarios/]
            JOB_S1[📄 job-s1.html<br/>JOB S1: Cold Call to Placement<br/>Complete business scenario]
            TMP_S1[📄 tmp-s1.html<br/>TMP S1: Pool Management<br/>Temporary staffing scenario]
            ADMIN_S1[📄 admin-s1.html<br/>ADMIN S1: Platform Management<br/>Administrative scenario]
        end
        
        subgraph "🎯 /features/ - Development Layer"
            FEATURES_DIR[📁 features/]
            
            subgraph "F001 - Job Search & Discovery"
                F001_DIR[📁 job-search-discovery/]
                F001_BIZ[📋 business/<br/>• scenarios.html<br/>• user-stories.html<br/>• requirements.html]
                F001_DES[🎨 design/<br/>• mockups.html<br/>• components.html<br/>• user-flows.html]
                F001_TEST[🐛 testing/<br/>• test-cases.html<br/>• acceptance-criteria.html<br/>• quality-metrics.html]
                F001_TECH[⚙️ technical/<br/>• specifications.html<br/>• api-docs.html<br/>• database-schema.html]
            end
        end
        
        subgraph "🎯 /use-cases/ - Functional Requirements Layer"
            USECASES_DIR[📁 use-cases/]
            UC001[📄 UC-001-organization-onboarding.html<br/>Cross-participant functional requirement<br/>Maps to: F001-Business + F001-Design + F001-Testing + F001-Technical]
            UC002[📄 UC-002-professional-recruitment.html<br/>Cross-participant functional requirement<br/>Maps to: Multiple features and participants]
            UC003[📄 UC-003-placement-coordination.html<br/>Cross-participant functional requirement<br/>Maps to: Multiple features and participants]
            UC004[📄 UC-004-multi-party-communication.html<br/>Cross-participant functional requirement<br/>Maps to: Multiple features and participants]
        end
        
        subgraph "📊 /unified-table/ - Progress Tracking"
            UNIFIED_DIR[📁 unified-table/]
            PROGRESS[📄 index.html<br/>Master progress tracker<br/>Shows completion across all layers]
        end
        
        subgraph "🗂️ /legacy/ - Current Implementation"
            LEGACY_DIR[📁 legacy/]
            SITEMAP[📁 sitemap/<br/>Current user story files<br/>s1.html, s2.html, etc.]
            PARTICIPANTS[📁 participants/<br/>Current participant domains<br/>scenarios/, ux-ui/, testing/, features/]
        end
    end
    
    %% Structure relationships
    ROOT --> SCENARIO_DIR
    ROOT --> FEATURES_DIR
    ROOT --> USECASES_DIR
    ROOT --> UNIFIED_DIR
    ROOT --> LEGACY_DIR
    
    SCENARIO_DIR --> JOB_S1
    SCENARIO_DIR --> TMP_S1
    SCENARIO_DIR --> ADMIN_S1
    
    FEATURES_DIR --> F001_DIR
    F001_DIR --> F001_BIZ
    F001_DIR --> F001_DES
    F001_DIR --> F001_TEST
    F001_DIR --> F001_TECH
    
    USECASES_DIR --> UC001
    USECASES_DIR --> UC002
    USECASES_DIR --> UC003
    USECASES_DIR --> UC004
    
    UNIFIED_DIR --> PROGRESS
    
    LEGACY_DIR --> SITEMAP
    LEGACY_DIR --> PARTICIPANTS
    
    %% Cross-layer relationships
    JOB_S1 -.-> F001_BIZ
    F001_BIZ -.-> UC001
    F001_DES -.-> UC001
    F001_TEST -.-> UC001
    F001_TECH -.-> UC001
    
    UC001 -.-> PROGRESS
    UC002 -.-> PROGRESS
    UC003 -.-> PROGRESS
    UC004 -.-> PROGRESS
    
    %% Migration path from legacy
    SITEMAP -.-> JOB_S1
    PARTICIPANTS -.-> F001_BIZ
    
    %% Styling
    classDef rootLevel fill:#fce4ec,stroke:#880e4f,stroke-width:3px
    classDef scenarioLevel fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef featureLevel fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef useCaseLevel fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef unifiedLevel fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef legacyLevel fill:#ffebee,stroke:#d32f2f,stroke-width:1px
    classDef participantLevel fill:#e3f2fd,stroke:#1976d2,stroke-width:1px
    
    class ROOT rootLevel
    class SCENARIO_DIR,JOB_S1,TMP_S1,ADMIN_S1 scenarioLevel
    class FEATURES_DIR,F001_DIR featureLevel
    class F001_BIZ,F001_DES,F001_TEST,F001_TECH participantLevel
    class USECASES_DIR,UC001,UC002,UC003,UC004 useCaseLevel
    class UNIFIED_DIR,PROGRESS unifiedLevel
    class LEGACY_DIR,SITEMAP,PARTICIPANTS legacyLevel
```

---

## 🎯 **Implementation Recommendations**

### **Missing Content Layer: Use Cases**

Currently implemented:
- ✅ **Scenarios** (in sitemap structure)
- ✅ **User Stories** (as individual step files)

Missing layer:
- ❌ **Use Cases** (functional requirements spanning participants)

### **Recommended Implementation**

1. **Create use-cases.html files** in business analysis sections
2. **Map use cases to existing user stories** 
3. **Define cross-participant functional requirements**
4. **Link use cases to design, testing, and technical requirements**

### **Example Use Case Documentation Structure**

```
/docs/site/features/job-search-discovery/business/use-cases.html
├── UC-001: Healthcare Organization Onboarding
├── UC-002: Healthcare Professional Recruitment  
├── UC-003: Placement Coordination & Management
└── UC-004: Multi-Party Communication System
```

Each use case would contain:
- **Functional Description**: What business value it delivers
- **Participant Mapping**: Which user stories from which participants
- **Dependencies**: What other use cases it depends on
- **Acceptance Criteria**: How success is measured
- **Cross-References**: Links to related design, testing, technical docs

This missing layer would provide the **functional requirement bridge** between high-level scenarios and detailed implementation steps, making the documentation structure complete and fully traceable.
