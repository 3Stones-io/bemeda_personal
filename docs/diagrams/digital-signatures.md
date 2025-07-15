# Digital Signature Workflow

## Current Implementation

```mermaid
sequenceDiagram
    participant C as Candidate
    participant S as System
    participant G as GenServer
    participant SP as SignWell Provider
    participant E as Employer
    
    Note over C,E: Job Offer Accepted
    
    C->>S: Request Contract Signing
    S->>S: Generate Contract from Template
    S->>G: Start Signing Session
    G->>SP: Create Signing Session
    SP-->>G: Return Signing URL
    G-->>S: Session Created
    S-->>C: Redirect to Signing URL
    
    C->>SP: Sign Document
    SP->>SP: Process Signature
    SP->>G: Webhook: Document Signed
    G->>S: Update Application Status
    S->>E: Notify Contract Signed
    S->>C: Confirm Contract Completion
    
    classDef implemented fill:#4F46E5,stroke:#333,stroke-width:2px,color:#fff
    classDef external fill:#94A3B8,stroke:#333,stroke-width:2px,color:#fff
    
    class C,S,G,E implemented
    class SP external
```

## Architecture Components

```mermaid
graph TB
    subgraph "Digital Signatures Context"
        DSM[DigitalSignatures Module]
        PM[ProviderManager]
        SM[SessionManager]
        SS[SessionSupervisor]
    end
    
    subgraph "Providers"
        MOCK[Mock Provider]
        SW[SignWell Provider]
        FUTURE[Future Providers]
    end
    
    subgraph "External Services"
        SWA[SignWell API]
        LO[LibreOffice]
        TS[Tigris Storage]
    end
    
    DSM --> PM
    DSM --> SM
    SM --> SS
    
    PM --> MOCK
    PM --> SW
    PM -.-> FUTURE
    
    SW --> SWA
    DSM --> LO
    DSM --> TS
    
    classDef implemented fill:#4F46E5,stroke:#333,stroke-width:2px,color:#fff
    classDef external fill:#94A3B8,stroke:#333,stroke-width:2px,color:#fff
    classDef future fill:#22C55E,stroke:#333,stroke-width:2px,color:#fff,stroke-dasharray: 5 5
    
    class DSM,PM,SM,SS,MOCK,SW,LO,TS implemented
    class SWA external
    class FUTURE future
```

## Session Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Initializing
    Initializing --> Created : Provider Session Created
    Created --> Pending : Signing URL Generated
    Pending --> InProgress : User Starts Signing
    InProgress --> Completed : Document Signed
    InProgress --> Cancelled : User Cancels
    InProgress --> Failed : Signing Error
    Completed --> [*]
    Cancelled --> [*]
    Failed --> [*]
    
    note right of Completed : Updates Job Application\nto "Contracted" status
    note right of Failed : Notifies employer\nand candidate
    
    classDef implemented fill:#4F46E5,stroke:#333,stroke-width:2px,color:#fff
    class Initializing,Created,Pending,InProgress,Completed,Cancelled,Failed implemented
```

## Contract Generation Process

```mermaid
flowchart TD
    A[Job Offer Accepted] --> B[Load Contract Template]
    B --> C[Extract Variables from Job Offer]
    C --> D[Generate Contract with LibreOffice]
    D --> E[Upload to Tigris Storage]
    E --> F[Create Signing Session]
    F --> G[Send to SignWell]
    G --> H[Return Signing URL]
    H --> I[Notify Candidate]
    
    J[Document Signed] --> K[Download Signed Contract]
    K --> L[Store in Tigris]
    L --> M[Update Application Status]
    M --> N[Notify All Parties]
    
    classDef implemented fill:#4F46E5,stroke:#333,stroke-width:2px,color:#fff
    
    class A,B,C,D,E,F,G,H,I,J,K,L,M,N implemented
```