# BemedaPersonal Documentation

This documentation site provides comprehensive system architecture and requirements engineering analysis for the BemedaPersonal Swiss manpower matching platform.

## 📋 Contents

### 🎯 [System Overview](index.html)

Interactive presentation covering the current system architecture, technology stack, and core functionality.

### 📊 [Use Case Analysis](diagrams/use-cases.html)

Detailed use case diagrams showing current functionality and proposed enhancements for the Swiss market.

### 🔄 [Application Lifecycle](presentations/application-lifecycle.html)

State machine diagrams illustrating the job application process from submission to contract signing.

### ✍️ [Digital Signatures](diagrams/digital-signatures.html)

Sequence diagrams and architecture overview of the digital signature workflow using SignWell integration.

### 🔍 [Gap Analysis](presentations/gap-analysis.html)

Analysis of missing features critical for Swiss manpower business operations.

## 🎨 Color Coding Legend

Throughout all diagrams, we use consistent color coding to indicate feature status:

- 🟦 **Blue (Solid)**: Currently implemented features
- 🟥 **Red (Dashed)**: Critical missing features required for Swiss market
- 🟧 **Orange (Dotted)**: Important enhancements for competitive advantage
- 🟩 **Green (Dash-dot)**: Nice-to-have features for future roadmap
- 🟪 **Purple (Double)**: Technical infrastructure improvements

## 🏗️ Architecture Overview

BemedaPersonal is built with:

- **Phoenix LiveView** - Real-time web interface
- **Elixir/OTP** - Concurrent, fault-tolerant backend
- **PostgreSQL** - Primary database
- **Oban** - Background job processing
- **FSMX** - State machine for application lifecycle
- **SignWell** - Digital signature provider
- **Tigris** - Document storage
- **Multi-language** - German, English, French, Italian support

## 🚀 Key Features

### Current Implementation

- User authentication with role-based routing
- Job posting and application management
- Resume building and management
- Company profiles and management
- Digital signature workflows
- Real-time messaging
- Multi-language support
- Rating system

### Swiss Market Enhancements Needed

- Payroll integration and processing
- Work permit management and validation
- Compliance reporting (SUVA, AHV, etc.)
- Timesheet and billing systems
- Background check workflows
- Mobile application
- Advanced matching algorithms

## 📱 Viewing the Presentations

### Online Access

Once deployed to GitHub Pages, access the presentations at:

- **Main Presentation**: `https://your-username.github.io/bemeda_personal/`
- **Individual Diagrams**: Navigate through the site or use direct links

### Local Development

```bash
cd docs
npm install
npm run serve
```

Then open `http://localhost:8080` in your browser.

### Navigation

- **Arrow Keys**: Navigate slides
- **Space**: Next slide
- **Escape**: Slide overview
- **F**: Fullscreen mode
- **S**: Speaker notes

## 🔧 Technical Details

### Mermaid Integration

All diagrams are created using Mermaid.js with custom styling and interactive features:

- Click on diagram elements for additional information
- Consistent color coding across all diagrams
- Responsive design for different screen sizes

### Reveal.js Features

- Smooth transitions between slides
- Code syntax highlighting
- Markdown support for content
- Plugin architecture for extensions

## 📈 Implementation Roadmap

1. **Phase 1**: Critical Swiss requirements (Payroll, Work Permits)
2. **Phase 2**: User experience enhancements (Mobile app, Skills assessment)
3. **Phase 3**: Advanced features (AI matching, Video interviewing)
4. **Phase 4**: Technical improvements (Microservices, Advanced analytics)

## 🤝 Contributing

To update the documentation:

1. Edit files in the `/docs` directory
2. Diagrams are in `/docs/diagrams/` as Markdown files with Mermaid code
3. Presentations are in `/docs/presentations/`
4. Push changes to trigger automatic deployment via GitHub Actions

## 📞 Support

For questions about the system architecture or requirements, please refer to the main project [README](../README.md) or [CLAUDE.md](../CLAUDE.md) files.
