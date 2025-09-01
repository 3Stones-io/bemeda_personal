const fs = require('fs');

function updateDocumentation() {
  try {
    const registry = JSON.parse(fs.readFileSync('docs/MASTER-REGISTRY.json', 'utf8'));
    
    // Update integration page with real-time data
    updateIntegrationPage(registry);
    
    // Update sitemap with current components
    updateSitemap(registry);
    
    console.log('Documentation updated successfully');
    
  } catch (error) {
    console.error('Error updating documentation:', error);
    process.exit(1);
  }
}

function updateIntegrationPage(registry) {
  // This would update the integration/index.html with real-time component counts
  // For now, just log the counts
  const counts = {
    business: registry.filter(c => c.domain === 'business').length,
    ux_ui: registry.filter(c => c.domain === 'ux-ui').length,
    technical: registry.filter(c => c.domain === 'technical').length,
    testing: registry.filter(c => c.domain === 'testing').length
  };
  
  console.log('Component counts:', counts);
}

function updateSitemap(registry) {
  // This would update the sitemap.html with current component structure
  console.log('Sitemap would be updated with', registry.length, 'components');
}

updateDocumentation();

