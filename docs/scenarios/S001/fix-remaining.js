const fs = require('fs');

// Read the current file
let content = fs.readFileSync('index.html', 'utf8');

// Define the remaining sections to replace
const replacements = [
  // JobSeeker US008
  {
    old: `                        <div class="process-step">
                            <span class="standard-id id-user-story">B_S001_US008</span>
                            <span class="step-text">Receive Job Notification</span>
                            <div class="step-links">
                                <a href="US008.html" class="step-link">Details</a>
                                <a href="https://github.com/3Stones-io/bemeda_personal/issues?q=is%3Aissue+label%3Acomponent+B_S001_US008" target="_blank" class="step-link github">GitHub</a>
                            </div>
                        </div>`,
    new: `                        <div class="process-step">
                            <div class="step-id">B_S001_US008_USS001</div>
                            <div class="step-text">Get matched job alert</div>
                            <div class="step-links">
                                <a href="US008.html" class="step-link">Details</a>
                                <a href="https://github.com/3Stones-io/bemeda_personal/issues?q=is%3Aissue+label%3Acomponent+B_S001_US008_USS001" target="_blank" class="step-link github">GitHub</a>
                            </div>
                        </div>
                        <div class="process-step">
                            <div class="step-id">B_S001_US008_USS002</div>
                            <div class="step-text">Review job details</div>
                            <div class="step-links">
                                <a href="US008.html" class="step-link">Details</a>
                                <a href="https://github.com/3Stones-io/bemeda_personal/issues?q=is%3Aissue+label%3Acomponent+B_S001_US008_USS002" target="_blank" class="step-link github">GitHub</a>
                            </div>
                        </div>
                        <div class="process-step">
                            <div class="step-id">B_S001_US008_USS003</div>
                            <div class="step-text">Assess job fit</div>
                            <div class="step-links">
                                <a href="US008.html" class="step-link">Details</a>
                                <a href="https://github.com/3Stones-io/bemeda_personal/issues?q=is%3Aissue+label%3Acomponent+B_S001_US008_USS003" target="_blank" class="step-link github">GitHub</a>
                            </div>
                        </div>`
  },
  // And continue with other replacements...
];

// Apply all replacements
let updatedContent = content;
replacements.forEach(replacement => {
  updatedContent = updatedContent.replace(replacement.old, replacement.new);
});

// Write back to file
fs.writeFileSync('index.html', updatedContent);
console.log('File updated successfully!');