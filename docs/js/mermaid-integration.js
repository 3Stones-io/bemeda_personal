// Mermaid integration for Reveal.js presentations

(function() {
    'use strict';
    
    // Initialize Mermaid with custom configuration
    const initMermaid = () => {
        mermaid.initialize({
            startOnLoad: false,
            theme: 'base',
            themeVariables: {
                // Implemented features (blue)
                primaryColor: '#4F46E5',
                primaryTextColor: '#FFFFFF',
                primaryBorderColor: '#3730A3',
                
                // Critical missing features (red)  
                secondaryColor: '#EF4444',
                secondaryTextColor: '#FFFFFF',
                secondaryBorderColor: '#DC2626',
                
                // Enhancement features (orange)
                tertiaryColor: '#F97316',
                tertiaryTextColor: '#FFFFFF',
                tertiaryBorderColor: '#EA580C',
                
                // Future features (green)
                quaternaryColor: '#22C55E',
                quaternaryTextColor: '#FFFFFF',
                quaternaryBorderColor: '#16A34A',
                
                // Technical features (purple)
                background: '#8B5CF6',
                backgroundTextColor: '#FFFFFF',
                
                // Base colors
                mainBkg: '#FFFFFF',
                secondBkg: '#F8FAFC',
                lineColor: '#64748B',
                textColor: '#1E293B',
                
                // Node styling
                nodeBkg: '#FFFFFF',
                nodeBorder: '#CBD5E1',
                clusterBkg: '#F1F5F9',
                clusterBorder: '#94A3B8',
                
                // Flowchart specific
                fillType0: '#4F46E5', // Implemented
                fillType1: '#EF4444', // Critical
                fillType2: '#F97316', // Enhancement
                fillType3: '#22C55E', // Future
                fillType4: '#8B5CF6', // Technical
            },
            flowchart: {
                useMaxWidth: false,
                htmlLabels: true,
                curve: 'basis',
                padding: 20,
                nodeSpacing: 50,
                rankSpacing: 50
            },
            sequence: {
                useMaxWidth: false,
                actorMargin: 50,
                width: 150,
                height: 65,
                boxMargin: 10,
                boxTextMargin: 5,
                noteMargin: 10,
                messageMargin: 35
            },
            gantt: {
                useMaxWidth: false,
                leftPadding: 75,
                gridLineStartPadding: 35,
                fontSize: 14,
                sectionFontSize: 16,
                numberSectionStyles: 4
            },
            journey: {
                useMaxWidth: false
            },
            gitgraph: {
                useMaxWidth: false
            }
        });
    };
    
    // Render all Mermaid diagrams on slide change
    const renderMermaidDiagrams = () => {
        const mermaidDivs = document.querySelectorAll('.mermaid');
        
        mermaidDivs.forEach((div, index) => {
            if (div.getAttribute('data-processed') !== 'true') {
                const graphDefinition = div.textContent || div.innerText;
                const graphId = `mermaid-${index}-${Date.now()}`;
                
                try {
                    mermaid.render(graphId, graphDefinition).then(({ svg }) => {
                        div.innerHTML = svg;
                        div.setAttribute('data-processed', 'true');
                        
                        // Add click handlers for interactive elements
                        addClickHandlers(div);
                    });
                } catch (error) {
                    console.error('Mermaid rendering error:', error);
                    div.innerHTML = `<p style="color: red;">Error rendering diagram: ${error.message}</p>`;
                }
            }
        });
    };
    
    // Add click handlers for interactive diagram elements
    const addClickHandlers = (container) => {
        const nodes = container.querySelectorAll('[id*="flowchart-"], [id*="node-"]');
        
        nodes.forEach(node => {
            node.style.cursor = 'pointer';
            node.addEventListener('click', (e) => {
                const nodeId = e.target.closest('[id]').id;
                const nodeText = e.target.textContent || e.target.innerText;
                
                // Show tooltip or navigate to code
                showNodeInfo(nodeText, e.pageX, e.pageY);
            });
        });
    };
    
    // Show information tooltip for clicked nodes
    const showNodeInfo = (nodeText, x, y) => {
        // Remove existing tooltips
        const existingTooltips = document.querySelectorAll('.mermaid-tooltip');
        existingTooltips.forEach(tooltip => tooltip.remove());
        
        const tooltip = document.createElement('div');
        tooltip.className = 'mermaid-tooltip';
        tooltip.style.cssText = `
            position: fixed;
            left: ${x + 10}px;
            top: ${y - 10}px;
            background: rgba(0, 0, 0, 0.9);
            color: white;
            padding: 8px 12px;
            border-radius: 4px;
            font-size: 12px;
            z-index: 10000;
            pointer-events: none;
            max-width: 200px;
        `;
        
        // Add feature status information
        let status = 'Unknown';
        let description = '';
        
        if (nodeText.includes('Register') || nodeText.includes('Apply') || nodeText.includes('Phoenix')) {
            status = 'Implemented';
            description = 'Currently available in the system';
        } else if (nodeText.includes('Payroll') || nodeText.includes('Timesheet')) {
            status = 'Critical Missing';
            description = 'Required for Swiss manpower business';
        } else if (nodeText.includes('Skills') || nodeText.includes('Mobile')) {
            status = 'Enhancement';
            description = 'Would improve user experience';
        }
        
        tooltip.innerHTML = `
            <strong>${nodeText}</strong><br>
            Status: <span class="status-${status.toLowerCase().replace(' ', '-')}">${status}</span><br>
            ${description}
        `;
        
        document.body.appendChild(tooltip);
        
        // Remove tooltip after 3 seconds
        setTimeout(() => {
            if (tooltip.parentNode) {
                tooltip.parentNode.removeChild(tooltip);
            }
        }, 3000);
    };
    
    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initMermaid);
    } else {
        initMermaid();
    }
    
    // Re-render diagrams on slide changes
    if (typeof Reveal !== 'undefined') {
        Reveal.addEventListener('slidechanged', () => {
            setTimeout(renderMermaidDiagrams, 100);
        });
        
        Reveal.addEventListener('ready', () => {
            setTimeout(renderMermaidDiagrams, 500);
        });
    }
    
    // Expose functions for manual control
    window.mermaidIntegration = {
        render: renderMermaidDiagrams,
        init: initMermaid
    };
})();