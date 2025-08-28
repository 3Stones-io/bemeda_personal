const fs = require('fs');

function generateComponentMap() {
  try {
    const registry = JSON.parse(fs.readFileSync('docs/MASTER-REGISTRY.json', 'utf8'));
    
    const componentMap = {
      generated_at: new Date().toISOString(),
      total_components: registry.length,
      by_domain: {},
      by_type: {},
      by_scenario: {},
      by_participant: {},
      by_status: {},
      hierarchical: {}
    };
    
    registry.forEach(component => {
      // Group by domain
      if (!componentMap.by_domain[component.domain]) {
        componentMap.by_domain[component.domain] = [];
      }
      componentMap.by_domain[component.domain].push(component.component_id);
      
      // Group by type
      if (!componentMap.by_type[component.component_type]) {
        componentMap.by_type[component.component_type] = [];
      }
      componentMap.by_type[component.component_type].push(component.component_id);
      
      // Group by scenario
      if (!componentMap.by_scenario[component.scenario]) {
        componentMap.by_scenario[component.scenario] = [];
      }
      componentMap.by_scenario[component.scenario].push(component.component_id);
      
      // Group by participant
      if (!componentMap.by_participant[component.participant]) {
        componentMap.by_participant[component.participant] = [];
      }
      componentMap.by_participant[component.participant].push(component.component_id);
      
      // Group by status
      if (!componentMap.by_status[component.status]) {
        componentMap.by_status[component.status] = [];
      }
      componentMap.by_status[component.status].push(component.component_id);
      
      // Build hierarchical structure
      buildHierarchical(componentMap.hierarchical, component);
    });
    
    fs.writeFileSync('docs/COMPONENT-MAP.json', JSON.stringify(componentMap, null, 2));
    console.log('Component map generated successfully');
    
  } catch (error) {
    console.error('Error generating component map:', error);
    process.exit(1);
  }
}

function buildHierarchical(hierarchical, component) {
  const parts = component.component_id.split('_');
  
  if (parts.length >= 2) {
    const scenario = parts[0] + '_' + parts[1];
    
    if (!hierarchical[scenario]) {
      hierarchical[scenario] = {
        type: parts[0] === 'B' ? 'business' : parts[0] === 'U' ? 'ux' : parts[0] === 'T' ? 'technical' : 'testing',
        components: {}
      };
    }
    
    if (parts.length === 2) {
      // Scenario level
      hierarchical[scenario].title = component.title;
      hierarchical[scenario].description = component.description;
    } else if (parts.length >= 3) {
      // Component level
      const componentKey = parts.slice(2).join('_');
      if (!hierarchical[scenario].components[componentKey]) {
        hierarchical[scenario].components[componentKey] = [];
      }
      hierarchical[scenario].components[componentKey].push(component.component_id);
    }
  }
}

generateComponentMap();
